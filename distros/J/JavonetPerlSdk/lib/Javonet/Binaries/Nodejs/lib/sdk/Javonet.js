const { RuntimeFactory, InMemoryConnectionData, WsConnectionData } = require('../..')

const Transmitter = require('../core/transmitter/Transmitter')
const ConfigRuntimeFactory = require('./ConfigRuntimeFactory')
const RuntimeLogger = require('../utils/RuntimeLogger')
const TcpConnectionData = require('../utils/connectionData/TcpConnectionData')
const { mkdirSync } = require('node:fs')

/**
 * The Javonet class is a singleton class that serves as the entry point for interacting with Javonet.
 * It provides methods to activate and initialize the Javonet SDK.
 * It supports both in-memory and TCP connections.
 * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/javonet-static-class)
 */
class Javonet {
    // Static block to initialize the Transmitter
    static {
        //SDKExceptionHelper.sendExceptionToAppInsights("SdkMessage", "Javonet SDK initialized");
    }

    /**
     * Initializes Javonet using an in-memory channel on the same machine.
     * @returns {RuntimeFactory} A RuntimeFactory instance configured for an in-memory connection.
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/in-memory-channel)
     */
    static inMemory() {
        return new RuntimeFactory(new InMemoryConnectionData())
    }

    /**
     * Initializes Javonet with a TCP connection to a remote machine.
     * @param {TcpConnectionData} tcpConnectionData - The tcp connection data of the remote machine.
     * @returns {RuntimeFactory} A RuntimeFactory instance configured for a TCP connection.
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/tcp-channel)
     */
    static tcp(tcpConnectionData) {
        return new RuntimeFactory(tcpConnectionData)
    }

    /**
     * Initializes Javonet with a WebSocket connection to a remote machine.
     * @param {WsConnectionData} wsConnectionData - The WebSocket connection data of the remote machine.
     * @returns {RuntimeFactory} A RuntimeFactory instance configured for a WebSocket connection.
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/websocket-channel)
     */
    static ws(wsConnectionData) {
        return new RuntimeFactory(wsConnectionData)
    }

    /**
     * Initializes Javonet with a custom configuration file taken from external source.
     * Currentyl supported: Configuration file in JSON format
     * @param {string} configPath - Path to a configuration file.
     * @returns {ConfigRuntimeFactory} A ConfigRuntimeFactory instance with configuration data.
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/configure-channel)
     */
    static withConfig(configPath) {
        return new ConfigRuntimeFactory(configPath)
    }

    /**
     * Activates Javonet with the provided license key.
     * @param {string} licenseKey - The license key to activate Javonet.
     * @returns {number} The activation status code.
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/getting-started/activating-javonet)
     */
    static activate(licenseKey) {
        return Transmitter.activate(licenseKey)
    }

    static getRuntimeInfo() {
        return RuntimeLogger.getRuntimeInfo()
    }

    /**
     * Sets the configuration source for the Javonet SDK.
     *
     * @param {string} configSource - The configuration source.
     */
    static setConfigSource(configSource) {
        Transmitter.setConfigSource(configSource)
    }

    /**
     * Sets the working directory for the Javonet SDK.
     *
     * @param {string} path - The working directory.
     */
    static setJavonetWorkingDirectory(path) {
        path = path.replace(/\\/g, "/");
        if (!path.endsWith("/")) {
            path += "/";
        }

        mkdirSync(path, { recursive: true, mode: 0o700 });
        Transmitter.setJavonetWorkingDirectory(path)
    }

}

module.exports = {
    Javonet,
    TcpConnectionData,
    WsConnectionData,
}
