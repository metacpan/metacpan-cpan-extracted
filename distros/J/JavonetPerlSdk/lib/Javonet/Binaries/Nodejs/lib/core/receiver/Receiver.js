const { InMemoryConnectionData, CommandSerializer, Interpreter } = require('../../..')

let RuntimeLogger

class Receiver {
    static connectionData = new InMemoryConnectionData()
    Receiver() {
        if (!RuntimeLogger) {
            RuntimeLogger = require('../../utils/RuntimeLogger')
        }
        RuntimeLogger.printRuntimeInfo()
    }

    /**
     * @param {number[]} messageByteArray
     */
    static sendCommand(messageByteArray) {
        return new CommandSerializer().serialize(
            new Interpreter().process(messageByteArray),
            this.connectionData
        )
    }

    static heartBeat(messageByteArray) {
        let response = new Int8Array(2)
        response[0] = messageByteArray[11]
        response[1] = messageByteArray[12] - 2
        return response
    }
}

module.exports = Receiver
