const wrapper = require('./TransmitterWrapper')

class Transmitter {
    static initialize() {
        return wrapper.initialize()
    }

    static sendCommand(messageArray) {
        return wrapper.sendCommand(messageArray)
    }

    static activate = function (licenseKey) {
        return wrapper.activate(licenseKey)
    }

    static setConfigSource(configSource) {
        return wrapper.setConfigSource(configSource)
    }
}

module.exports = Transmitter
