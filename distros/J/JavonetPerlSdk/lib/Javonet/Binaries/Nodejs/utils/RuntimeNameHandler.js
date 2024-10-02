const RuntimeName = require('./RuntimeName');

class RuntimeNameHandler {
    static getName(runtimeName) {
        switch (runtimeName) {
            case RuntimeName.Clr:
                return "clr";
            case RuntimeName.Go:
                return "go";
            case RuntimeName.Jvm:
                return "jvm";
            case RuntimeName.Netcore:
                return "netcore";
            case RuntimeName.Perl:
                return "perl";
            case RuntimeName.Python:
                return "python";
            case RuntimeName.Ruby:
                return "ruby";
            case RuntimeName.Nodejs:
                return "nodejs";
            case RuntimeName.Cpp:
                return "cpp";
            default:
                throw new Error("Invalid runtime name.");
        }
    }
}

module.exports = RuntimeNameHandler;