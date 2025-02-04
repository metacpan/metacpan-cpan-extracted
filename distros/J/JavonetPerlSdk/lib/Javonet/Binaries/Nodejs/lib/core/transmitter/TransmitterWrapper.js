let library

class TransmitterWrapper {

    static isNativeLibraryLoaded() {
        return library !== undefined
    }

    static loadNativeLibrary() {
        if (this.isNativeLibraryLoaded()) {
            return
        }

        let binariesRootPath = String(`${require('path').resolve(__dirname, '../../../../')}`)

        const nativeAddonPath = `${binariesRootPath}/build/Release/JavonetNodejsRuntimeAddon.node`

        library = require(nativeAddonPath)

        library.initializeTransmitter(binariesRootPath)
        // eslint-disable-next-line no-unused-vars
        const ReceiverNative = require('../receiver/ReceiverNative')
        library.setReceiverNative(global.ReceiverNative)
    }

    static activate(licenseKey) {
        this.loadNativeLibrary()
        return library.activate(licenseKey)
    }

    static sendCommand(messageArray) {
        this.loadNativeLibrary()
        return library.sendCommand(messageArray)
    }

    static setConfigSource(configSource) {
        this.loadNativeLibrary()
        return library.setConfigSource(configSource)
    }

    static setJavonetWorkingDirectory(path) {
        this.loadNativeLibrary()
        library.setWorkingDirectory(path)
    }
}

module.exports = TransmitterWrapper
