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
        evalModuleFile(file)

        if (modules[file]) {
            return modules[file].exports;
        }
    }

    global.require.__modules = modules;
    global.require.__callStack = callStack;

})(this)
