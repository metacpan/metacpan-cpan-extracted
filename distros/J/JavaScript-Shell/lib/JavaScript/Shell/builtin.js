(function(global){
    
    global.jshell = {};
    jshell.Contexts = {};
    jshell.print = print;
    jshell.putstr = putstr;
    
    global.print = undefined;
    global.putstr = undefined;
    
    var CloneObject = (function(source, target) {
        Object.getOwnPropertyNames(source).forEach(function(key) {
            try {
                var desc = Object.getOwnPropertyDescriptor(source, key);
                if (desc.value === source) desc.value = target;
                Object.defineProperty(target, key, desc);
            } catch (e) {
                throw(e);
                // Catch sealed properties errors\n\
            }
        });
    });
    
    jshell.setContext = function(id,sandbox){
        var context = newGlobal();
        
        //delete globals
        //for (var key in context) {
        //    delete context[key];
        //}
        
        context.print = undefined;
        context.putstr = undefined;
        
        if (sandbox) {
            if (typeof sandbox === 'object') {
                CloneObject(sandbox, context);
            } else {
                throw new Error("Context() accept only object as first argument.");
            }
        }
        context.jshell = global.jshell;
        jshell.Contexts[id] = context;
    };
    
    jshell.getContext = function(ctx){
        return ctx ? jshell.Contexts[ctx] : global;
    }
    
    jshell.__returnvalue = undefined;
    jshell.doReturn = function(ret){
        if (ret)
        jshell.__returnvalue = ret;
        return undefined;
    };
    
    //sending request to Perl -- IPC
    var _internalCounter = 1;
    jshell.send = function(options){
        options.id = _internalCounter++;
        try {
            var seen = [];
            var str = JSON.stringify(options, function(key, val) {
                if (typeof val == "object") {
                    if (seen.indexOf(val) >= 0) return undefined
                    seen.push(val);
                }
                return val
            });
            //var str = JSON.stringify(options);
            //jshell.print('to_perl[' + str + ']end_perl');
            jshell.print(str);
            return jshell.wait(options.id);
            
        } catch(e){
            throw new Error('could not call method ' + options.method  + ' ' + e);
        }
    };
    
    jshell.retCache = {};
    jshell.wait = function(id){
        while(1){
            eval( readline() );
            if (jshell.retCache.hasOwnProperty(id)){
                var ret = jshell.retCache[id];
                delete jshell.retCache[id];
                return ret;
            }
        }
    };
    
    jshell.sendBuffer = function(buf){
        jshell.print(buf);
        jshell.putstr('defdba7883bd47f7a043e0c9680d8b13');
    };
    
    jshell.setArgs = function(op){
        if (op._buffer) {
            jshell.retCache[op.id] = read(op._buffer);
            //jshell.retCache[op.id] = 1;
            //delete temp file
            jshell.send({
                method : '_deleteTempFile',
                args : op._buffer
            });
        } else {
            jshell.retCache[op.id] = op._args;
        }
    };
    
    //excuting functions
    jshell.execFunc = function(op){
        if (!op){
            return;
        }
        var fn = op.fn,
        args = op.args;
        
        //resolve function name space
        fn = this.resolveNameSpace(fn,op.context);
        var context = jshell.getContext(op.context);
        
        if (fn && typeof fn === 'function'){
            var ret = fn.apply(global,args);
        } else {
            throw new TypeError(op.fn + " is not a function");
        }
        
        return jshell.doReturn(ret);
    };
    
    
    jshell.resolveNameSpace = function(name,ctx,val){
        var names = name.split('.');
        var last = names.pop();
        var x = jshell.getContext(ctx);
        
        for(var i =0;i<names.length;i++){
            x = x[names[i]];
            if (typeof x === 'object' || typeof x === 'function'){}
            else {throw new Error('can not set '+ last +' - '+ names +' is not defined')}
        }
        
        if (val){
            x[last] = val;
        }
        
        return x[last];
    };
    
    jshell.endLoop = function(value){
        jshell.send({
            method : "__stopLoop",
            args : value
        });
    }
    
    jshell.setFunction = function(name,value,ctx,option){
        jshell.Set(name,function(){
            var ret = jshell.send({
                method : value,
                args : Array.slice(arguments,0)
            });
            return ret;
        },ctx);
    };
    
    jshell.Set = function(name, value, ctx){
        jshell.resolveNameSpace(name,ctx,value);
    };
    
    jshell.setValue = function(value){
        jshell.send({
            method : 'setValue',
            args : value
        });
    };
    
    jshell.getValue = function(name,ctx){
        var thing = jshell.resolveNameSpace(name,ctx),
        ret;
        if (typeof thing === 'function'){
            var args = Array.slice(arguments,2);
            ret = thing.apply({},args);
        } else {
            ret = thing;
        }
        
        jshell.setValue(ret);
        return undefined;
    };
    
    jshell.evalCode = function(code,ctx){
        var context = jshell.getContext(ctx);
        var ret = context.eval(code);
        return jshell.doReturn(ret);
    };
    
    jshell.sig = function(ii){
        jshell.print('Signal ' + ii);
    }
    
    while(1){
        try {
            eval(readline());
        } catch(e){
            jshell.onError({
                message : e.message || e.toString(),
                line : e.lineNumber || '',
                file : e.fileName || '',
                stack : e.stack || '',
                type : e.name || 'Error'
            });
        }
    }
    
})(this);
