let library

class TransmitterWrapper {
    static initialize() {
        if (process.platform === 'win32')
            library = require(
                `${require('path').resolve(__dirname, '../../../../')}/build/Release/JavonetNodejsRuntimeAddon.node`
            )
        else if (process.platform === 'darwin')
            library = require(
                `${require('path').resolve(__dirname, '../../../../')}/build/Release/JavonetNodejsRuntimeAddon.node`
            )
        else
            library = require(
                `${require('path').resolve(__dirname, '../../../../')}/build/Release/JavonetNodejsRuntimeAddon.node`
            )
        let binariesRootPath = String(`${require('path').resolve(__dirname, '../../../../')}`)
        return library.initializeTransmitter(binariesRootPath)
    }

    static activate(licenseKey) {
        return library.activate(licenseKey)
    }

    static sendCommand(messageArray) {
        return library.sendCommand(messageArray)
    }

    static setConfigSource(configSource) {
        return library.setConfigSource(configSource)
    }
}

module.exports = TransmitterWrapper
