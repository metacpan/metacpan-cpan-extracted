const Command = require("../../utils/Command")
const TypeEncoder = require('./TypeSerializer')
const Runtime = require('../../utils/RuntimeName')

class CommandSerializer {
    buffer = new Int8Array(2)


    serialize(root_command, connectionData, runtimeVersion = 0) {
        this.buffer[0] = root_command.runtimeName
        this.buffer[1] = runtimeVersion
        this.#insertIntoBuffer(connectionData.serializeConnectionData())
        this.#insertIntoBuffer(new Int8Array([Runtime.Nodejs, root_command.commandType]))
        this.#serializeRecursively(root_command)
        return this.buffer
    }

    #serializeRecursively = function(root_command) {
        for (let cmd of root_command.payload) {
            if (cmd instanceof Command) {
                this.#insertIntoBuffer(TypeEncoder.serializeCommand(cmd))
                this.#serializeRecursively(cmd)
            } else {
                let result = TypeEncoder.encodePrimitive(cmd)
                this.#insertIntoBuffer(result)
            }
        }
    }

    #insertIntoBuffer = function(arg) {
        let newArray = new Int8Array(this.buffer.length + arg.length)
        newArray.set(this.buffer, 0)
        newArray.set(arg, this.buffer.length)
        this.buffer = newArray
    }
}

module.exports = CommandSerializer