let CommandType = require('./CommandType')

class Command {
    constructor(runtimeName, commandType, payload = []) {
        this.runtimeName = runtimeName
        this.commandType = commandType
        this.payload = payload
    }

    static createResponse(response, runtimeName) {
        return new Command(
            runtimeName,
            CommandType.Value,
            [response]
        )
    }

    static createReference(response, runtimeName) {
        return new Command(
            runtimeName,
            CommandType.Reference,
            [response]
        )
    }

    static createArrayResponse(response, runtimeName) {
        return new Command(
            runtimeName,
            CommandType.Array,
            response
        )
    }

    dropFirstPayloadArg() {
        return new Command(
            this.runtimeName,
            this.commandType,
            this.payload.slice(1)
        )
    }

    addArgToPayload(arg) {
        return new Command(
            this.runtimeName,
            this.commandType,
            this.payload.concat(arg)
        )
    }

    prependArgToPayload(current_command) {
        if (current_command == null) {
            return new Command(
                this.runtimeName,
                this.commandType,
                this.payload)
        } else {
            return new Command(
                this.runtimeName,
                this.commandType,
                [current_command].concat(this.payload)
            )
        }
    }
}

module.exports = Command