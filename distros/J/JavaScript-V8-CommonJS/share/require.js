(function(global) {
    "use strict";

    var modules = {},
        callStack = [];

    global.require = function(id) {

        // native module
        var native = requireNative(id);
        if (native) {
            return native;
        }

        // resolve file
        var currentModule = callStack[callStack.length-1];
        // console.log("currentModule", currentModule);
        var file = resolveModule(id, currentModule ? currentModule.__filename : undefined);
        if (!file) {
            throw "Can't find module '" + id + "'"
        }

        // already cached
        if (modules[file]) {
            return modules[file].exports;
        }

        // circular require
        for (var i = 0; i < callStack.length; i++) {
            if (callStack[i].__filename == file) {
                return callStack[i].exports;
            }
        }

        // load module
        var moduleSource = readFile(file),
            module = {
                exports: {},
                __filename: file
            };

        // catch compilation error
        try {
            callStack.push(module);
            (function (require, module, exports, __filename, __dirname) { eval(moduleSource) })(global.require, module, module.exports, file);
            callStack.pop();
        }
        catch (e) {
            e.stack = e.stack.replace(/<anonymous>:(\d+:\d+\))/, file + ':' + "$1");
            callStack.pop();
            throw e;
        }

        // cache and return
        module.__filename = file;
        modules[file] = module;
        return modules[file].exports;
    }

})(this)
