const Interpreter = require('../interpreter/Interpreter')
const CommandSerializer = require("../protocol/CommandSerializer");
const InMemoryConnectionData = require("../../utils/connectionData/InMemoryConnectionData");
const interpreter = new Interpreter()

class Receiver {

    static connectionData = new InMemoryConnectionData();

    static sendCommand(messageByteArray) {
        return new CommandSerializer().serialize(interpreter.process(messageByteArray), this.connectionData)
    }
    static heartBeat(messageByteArray) {
        let response = new Int8Array(2)
        response[0] = messageByteArray[11]
        response[1] = messageByteArray[12]-2
        return response
    }
}

module.exports = Receiver
