const Receiver = require('./Receiver') 

class ReceiverNative {
    static sendCommand(messageByteArray) {
		return Receiver.sendCommand(messageByteArray)
    }

    static heartBeat(messageByteArray) {
        return Receiver.heartBeat(messageByteArray)
    }
}

global.ReceiverNative = ReceiverNative;
