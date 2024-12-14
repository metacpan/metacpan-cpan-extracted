const CommandType = require('./CommandType')

class Command {
    /**
     * Constructs a new Command instance.
     * @param {number} runtimeName - The runtime name associated with the command.
     * @param {number} commandType - The type of the command.
     * @param {any} [payload] - The optional payload of the command.
     * @method
     */
    constructor(runtimeName, commandType, payload = []) {
        this.runtimeName = runtimeName
        this.commandType = commandType
        this.payload = payload
    }

    /**
     * @param {any} [response]
     * @param {number} runtimeName
     */
    static createResponse(response, runtimeName) {
        return new Command(runtimeName, CommandType.Value, [response])
    }

    /**
     * @param {any} [response]
     * @param {number} runtimeName
     * @method
     */
    static createReference(response, runtimeName) {
        return new Command(runtimeName, CommandType.Reference, [response])
    }

    /**
     * @param {any} [response]
     * @param {number} runtimeName
     * @returns {Command}
     * @method
     */
    static createArrayResponse(response, runtimeName) {
        return new Command(runtimeName, CommandType.Array, response)
    }

    dropFirstPayloadArg() {
        return new Command(this.runtimeName, this.commandType, this.payload.slice(1))
    }

    /**
     * @param {any} arg
     * @returns {Command}
     */
    addArgToPayload(arg) {
        return new Command(this.runtimeName, this.commandType, this.payload.concat(arg))
    }

    /**
     * @param {Command|null} current_command
     * @returns {Command}
     */
    prependArgToPayload(current_command) {
        if (current_command == null) {
            return new Command(this.runtimeName, this.commandType, this.payload)
        } else {
            return new Command(this.runtimeName, this.commandType, [current_command].concat(this.payload))
        }
    }
}

module.exports = Command
