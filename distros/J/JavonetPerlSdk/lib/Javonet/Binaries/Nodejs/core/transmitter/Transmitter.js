const wrapper = require('./TransmitterWrapper')

class Transmitter {

   static sendCommand(messageArray) {
        return wrapper.sendCommand(messageArray)
    }

    static #activate = function(licenseKey = "", proxyHost = "", proxyUserName="", proxyUserPassword="") {
        return wrapper.activate(licenseKey, proxyHost, proxyUserName, proxyUserPassword)
    }

    static activateWithLicenseFile() {
        return this.#activate()
    }

    static activateWithCredentials(licenseKey) {
        return this.#activate(licenseKey)
    }

    static activateWithCredentialsAndProxy(licenseKey, proxyHost, proxyUserName, proxyUserPassword) {
        return this.#activate(licenseKey, proxyHost, proxyUserName, proxyUserPassword)
    }

    static setConfigSource(configSource) {
        return wrapper.setConfigSource(configSource)
    }
}

module.exports = Transmitter
