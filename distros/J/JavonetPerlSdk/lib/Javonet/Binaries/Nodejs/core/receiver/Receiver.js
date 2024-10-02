const Interpreter = require('../interpreter/Interpreter')
const interpreter = new Interpreter()

class Receiver {
    static sendCommand(messageByteArray) {
        return interpreter.process(messageByteArray)
    }
    static heartBeat(messageByteArray) {
        let response = new Int8Array(2)
        response[0] = messageByteArray[11]
        response[1] = messageByteArray[12]-2
        return response
    }
}

module.exports = Receiver
