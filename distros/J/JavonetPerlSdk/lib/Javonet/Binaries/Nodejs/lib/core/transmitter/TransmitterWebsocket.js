const WebSocketClient = require('../webSocketClient/WebSocketClient')

/** @typedef {import('../../../../core/lib/declarations').WsConnectionData} WsConnectionData */

class TransmitterWebsocket {
    /**
     * @returns {void}
     */
    static initialize() {}

    /**
     * @returns {void}
     */
    static setConfigSource() {}

    /**
     * @returns {void}
     */
    static activate() {}

    /**
     * @async
     * @param {number[]} messageByteArray
     * @param {WsConnectionData} connectionData
     * @returns {Promise<number[]>} responseByteArray
     */
    static async sendCommand(messageByteArray, connectionData) {
        const { hostname } = connectionData
        return new WebSocketClient(hostname).send(messageByteArray)
    }
}

module.exports = TransmitterWebsocket
