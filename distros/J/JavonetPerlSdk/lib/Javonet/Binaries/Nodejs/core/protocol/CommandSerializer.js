const Command = require("../../utils/Command")
const TypeEncoder = require('./TypeSerializer')
const ConnectionType = require("../../utils/ConnectionType");
const Runtime = require('../../utils/RuntimeName')

class CommandSerializer {
    buffer = new Int8Array(2)

    serialize(command, connectionType, tcpConnectionData = null, runtimeVersion = 0) {
        let deque = [command]
        this.buffer[0] = command.runtimeName
        this.buffer[1] = runtimeVersion
        this.#insertIntoBuffer(this.#serialize_tcp(connectionType, tcpConnectionData))
        this.#insertIntoBuffer(new Int8Array([Runtime.Nodejs, command.commandType]))
        return this.#encodeRecursively(deque)
    }

    #serialize_tcp = function(connectionType, tcpConnectionData) {
        let encodedTcp = new Int8Array(7)
        encodedTcp[0] = connectionType
        if (connectionType === ConnectionType.IN_MEMORY || tcpConnectionData === null) {
            encodedTcp[1] = 0
            encodedTcp[2] = 0
            encodedTcp[3] = 0
            encodedTcp[4] = 0
            encodedTcp[5] = 0
            encodedTcp[6] = 0
        }
        else if (ConnectionType.TCP === connectionType) {
            let address = tcpConnectionData.getAddressBytes()
            let port = tcpConnectionData.getPortBytes()
            encodedTcp[1] = address[0]
            encodedTcp[2] = address[1]
            encodedTcp[3] = address[2]
            encodedTcp[4] = address[3]
            encodedTcp[5] = port[0]
            encodedTcp[6] = port[1]
        }
        return encodedTcp
    }

    #encodeRecursively = function(deque) {
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
            return this.#encodeRecursively(deque)
        } else {
            deque.pop()
        }
        return this.#encodeRecursively(deque)
    }

    #insertIntoBuffer = function(arg) {
        let newArray = new Int8Array(this.buffer.length + arg.length)
        newArray.set(this.buffer, 0)
        newArray.set(arg, this.buffer.length)
        this.buffer = newArray
    }
}

module.exports = CommandSerializer