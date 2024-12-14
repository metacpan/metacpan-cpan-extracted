const ConnectionType = require('../ConnectionType')
const IConnectionData = require('./IConnectionData')

/** @typedef {import('../../declarations').ConnectionType} ConnectionType */

/**
 * Represents WebSocket connection data.
 * @extends IConnectionData
 */
class WsConnectionData extends IConnectionData {
    /**
     * @param {string} hostname - The hostname of the connection.
     */
    constructor(hostname) {
        super()
        /** @private @type {string} */
        this._hostname = hostname
        /** @private @type {ConnectionType} */
        this._connectionType = ConnectionType.WEB_SOCKET
    }

    /** @type {ConnectionType} */
    get connectionType() {
        return this._connectionType
    }

    /** @type {string} */
    get hostname() {
        return this._hostname
    }

    /** @type {string} */
    set hostname(value) {
        this._hostname = value
    }

    /**
     * Serializes the connection data.
     * @returns {number[]} An array of connection data values.
     */
    serializeConnectionData() {
        return [this.connectionType, 0, 0, 0, 0, 0, 0]
    }

    equals(other) {
        return other instanceof WsConnectionData && this._hostname === other.hostname
    }
}

module.exports = WsConnectionData
