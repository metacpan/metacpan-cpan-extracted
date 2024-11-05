const Interpreter = require('../interpreter/Interpreter')
const CommandSerializer = require("../protocol/CommandSerializer");
const InMemoryConnectionData = require("../../utils/connectionData/InMemoryConnectionData");
const RuntimeLogger = require("../../utils/RuntimeLogger");



class Receiver {

    static connectionData = new InMemoryConnectionData();
    Receiver() {
        RuntimeLogger.printRuntimeInfo()
    }

    static sendCommand(messageByteArray) {
        return new CommandSerializer().serialize(new Interpreter().process(messageByteArray), this.connectionData)
    }
    static heartBeat(messageByteArray) {
        let response = new Int8Array(2)
        response[0] = messageByteArray[11]
        response[1] = messageByteArray[12]-2
        return response
    }
}

module.exports = Receiver
