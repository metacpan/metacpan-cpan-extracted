const CommandType = require("../CommandType");
const Command = require("../Command");
const Runtime = require("../RuntimeName");
const ExceptionType = require("../ExceptionType");


class ExceptionSerializer {


    static serializeException(exception, command){
        let exceptionCommand = new Command(
            Runtime.Nodejs,
            CommandType.Exception,
            []
        )
        exceptionCommand = exceptionCommand.addArgToPayload(this.getExceptionCode(exception))
        exceptionCommand = exceptionCommand.addArgToPayload(command.toString())
        exceptionCommand = exceptionCommand.addArgToPayload(exception.name)
        exceptionCommand = exceptionCommand.addArgToPayload(exception.message)

        let stackClasses = []
        let stackMethods = []
        let stackLines = []
        let stackFiles = []

        this.serializeStackTrace(exception, stackClasses, stackMethods, stackLines, stackFiles)
        exceptionCommand = exceptionCommand.addArgToPayload(stackClasses.join("|"))
        exceptionCommand = exceptionCommand.addArgToPayload(stackMethods.join("|"))
        exceptionCommand = exceptionCommand.addArgToPayload(stackLines.join("|"))
        exceptionCommand = exceptionCommand.addArgToPayload(stackFiles.join("|"))

        return exceptionCommand
    }

    static getExceptionCode(exception) {
        switch (exception.name) {
            case "Error":
                return ExceptionType.EXCEPTION
            case "TypeError":
                return ExceptionType.ILLEGAL_ARGUMENT_EXCEPTION
            case "RangeError":
                return ExceptionType.INDEX_OUT_OF_BOUNDS_EXCEPTION
            default:
                return ExceptionType.EXCEPTION
        }
    }

    static serializeStackTrace(exception, stackClasses, stackMethods, stackLines, stackFiles) {
        const stackTrace = exception.stack.split('\n').slice(1);

        for (let i = 0; i < stackTrace.length; i++) {
            const parts = stackTrace[i].trim().match(/at\s(.*)\s\((.*):(\d+):(\d+)\)/);
            if (parts) {
                stackClasses.push(parts[1]);
                stackMethods.push('unknown');
                stackLines.push(parts[3]);
                stackFiles.push(parts[2]);
            } else {
                const parts = stackTrace[i].trim().match(/at\s(.*):(\d+):(\d+)/);
                if (parts) {
                    stackClasses.push('unknown');
                    stackMethods.push('unknown');
                    stackLines.push(parts[2]);
                    stackFiles.push(parts[1]);
                }
            }
        }
    }
}

module.exports = ExceptionSerializer
