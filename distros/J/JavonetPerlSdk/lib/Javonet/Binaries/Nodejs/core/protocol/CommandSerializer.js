const Command = require("../../utils/Command")
const TypeEncoder = require('./TypeSerializer')
const Runtime = require('../../utils/RuntimeName')

class CommandSerializer {
    buffer = new Int8Array(2)


    serialize(command, connectionData, runtimeVersion = 0) {
        let deque = [command]
        this.buffer[0] = command.runtimeName
        this.buffer[1] = runtimeVersion
        this.#insertIntoBuffer(connectionData.serializeConnectionData())
        this.#insertIntoBuffer(new Int8Array([Runtime.Nodejs, command.commandType]))
        return this.#serializeRecursively(deque)
    }

    #serializeRecursively = function(deque) {
        if (deque.length === 0) return this.buffer;
        let cmd = deque.pop()
        deque.push(cmd.dropFirstPayloadArg())
        if (cmd.payload.length > 0) {
            if (cmd.payload[0] instanceof Command) {
                let innerCommand = cmd.payload[0]
                this.#insertIntoBuffer(TypeEncoder.serializeCommand(innerCommand))
                deque.push(innerCommand)
            } else {
                let result = TypeEncoder.encodePrimitive(cmd.payload[0])
                this.#insertIntoBuffer(result)
            }
            return this.#serializeRecursively(deque)
        } else {
            deque.pop()
        }
        return this.#serializeRecursively(deque)
    }

    #insertIntoBuffer = function(arg) {
        let newArray = new Int8Array(this.buffer.length + arg.length)
        newArray.set(this.buffer, 0)
        newArray.set(arg, this.buffer.length)
        this.buffer = newArray
    }
}

module.exports = CommandSerializer