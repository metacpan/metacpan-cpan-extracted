(function(){
    var DependencyError = function(fqn){
        this.message = "dependency error ::"+ fqn ;
        this.name    = "DependencyError";
    };
    DependencyError.prototype = new Error();

    var InvalidNamespaceError = function(fqn){
        this.message = "namespace "+fqn+"must be composed from alphabet|digit|dot";
        this.name    = "InvalidNamespaceError";
    };
    InvalidNamespaceError.prototype = new Error();

    var curry = function(first,func){
        return function(){
            var args = [first];
            for(var i = 0,l=arguments.length;i<l;i++){
                args.push(arguments[i]);
            }
            return func.apply(this,args);
        };
    };
    var Namespace = (function(){
        var nsCache = {};
        var nsList  = [];
        var _Namespace = function _Namespace(fqn){
            this.FQN = fqn;
        };
        _Namespace.prototype.publish = function(obj){
            for( var p in obj ){
                if( p !== 'FQN' && obj.hasOwnProperty( p ) ){
                    this[p] = obj[p];
                }
            }
        };
        var _assertValidNamespace = function(fqn){
            if( !fqn.match(/^[a-z][a-z0-9.]+[a-z0-9]$/) ){
                throw(new InvalidNamespaceError(fqn));
            }
        };
        return {
            isCreated:function(fqn){
                _assertValidNamespace(fqn);
                return ( nsCache[fqn] )? true: false;
            },
            create :function(fqn){
                 _assertValidNamespace(fqn);
                if( nsCache[fqn] ){
                    return nsCache[fqn];
                }else{
                    var ns = new _Namespace(fqn);
                    nsCache[fqn] = ns;

                    nsList.push(fqn);
                    return ns;
                }
            },
            getList:function(){
                return nsList;
            },
            getChildren:function(fqn){
                _assertValidNamespace( fqn );
                var ret = []; 
                for(var i = 0,l= nsList.length,elem;i<l;i++){
                    elem = nsList[i];
                    if(elem.indexOf(fqn+".")===0){
                        ret.push(elem);
                    }
                }
                return ret;
            }
        };
    })();
    var export_depends = function depends(fqn,checkList){
        if( Namespace.isCreated(fqn) ){
            if( checkList ){
                var ns = Namespace.create( fqn );
                for(var i = 0,l=checkList.length;i<l;i++){
                    if( !ns[checkList[i]] ){
                        throw( new DependencyError(fqn+" "+checkList[i]) );
                    }
                }
                return true;
            }else{
                return true;
            }
        }else{
            throw( new DependencyError(fqn) );
        }
    };
    var export_within  = function within(fqn,exporter,callback){
        if(!Namespace.isCreated(fqn)){
            throw( new DependencyError(fqn) );
        }
        var ns   = Namespace.create(fqn);
        var args = [];
        for(var i = 0,l=exporter.length,elem;i<l;i++){
            elem = exporter[i];
            args.push( ns[elem] );
        }
        return callback.apply(this,args);
    };
    var export_using   = function using(fqn,callback){
        if( fqn === undefined ){
            return callback.apply(this);
        }
        var ns = Namespace.create( fqn ) ;
        return callback.apply(this,[ns]);
    };
    var export_stash = function stash(fqn){
        if(!Namespace.isCreated(fqn)){
            throw( new DependencyError(fqn) );
        }
        return Namespace.create(fqn);
    };
    String.prototype.namespace = function(){
        return {
            depends : curry( this , export_depends ),
            within  : curry( this , export_within  ),
            using   : curry( this , export_using   ),
            stash   : curry( this , export_stash   )
        };
    };
    "ectype.lang".namespace().using(function(NAMESPACE){
        NAMESPACE.publish({namespace:Namespace});
    });
    "ectype.exception".namespace().using(function(NAMESPACE){
        NAMESPACE.publish({
            DependencyError       : DependencyError,
            InvalidNamespaceError : InvalidNamespaceError
        });
    });
})();
