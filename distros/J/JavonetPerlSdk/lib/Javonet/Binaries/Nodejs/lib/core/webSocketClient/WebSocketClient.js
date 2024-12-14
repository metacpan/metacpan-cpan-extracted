const WebSocket = require('ws')

/**
 * Enum for WebSocket states.
 * @readonly
 * @enum {string}
 */
const WebSocketStateEnum = {
    OPEN: 'open',
    CLOSE: 'close',
    ERROR: 'error',
}

/**
 * WebSocketClient class that handles WebSocket connection, message sending, and automatic disconnection.
 */
class WebSocketClient {
    /**
     * @param {string} url
     * @param {object} options
     */
    constructor(url, options) {
        /**
         * @type {string}
         */
        this.url = url

        /**
         * @type {WebSocket | null}
         */
        this.instance = null

        /**
         * @type {boolean} isConnected indicates whether the WebSocket is connected.
         */
        this.isConnected = false

        /**
         * @type {boolean}
         */
        this.isDisconnectedAfterMessage = options?.isDisconnectedAfterMessage ?? false
    }

    /**
     * Sends messageArray through websocket connection
     * @async
     * @param {Buffer|ArrayBuffer|Buffer[]} messageArray
     * @returns {Promise<Buffer|ArrayBuffer|Buffer[]>}
     */
    send(messageArray) {
        return new Promise((resolve, reject) => {
            try {
                if (this.isConnected) {
                    this._sendMessage(messageArray, resolve, reject)
                } else {
                    this._connect().then(() => {
                        this._sendMessage(messageArray, resolve, reject)
                    })
                }
            } catch (error) {
                reject(error)
            }
        })
    }

    /**
     * Disconnects the WebSocket by terminating the connection.
     */
    disconnect() {
        if (this.instance) {
            this.instance.terminate()
        }
        this.isConnected = false
    }

    /**
     * Connects to the WebSocket server.
     * @private
     * @async
     * @returns {Promise<void>} - A promise that resolves when the connection is established.
     */
    _connect() {
        return new Promise((resolve, reject) => {
            this.instance = new WebSocket(this.url)

            this.instance.on(WebSocketStateEnum.OPEN, () => {
                this.isConnected = true
                resolve()
            })

            // eslint-disable-next-line no-unused-vars
            this.instance.on(WebSocketStateEnum.ERROR, (error) => {
                reject(null)
            })

            this.instance.on(WebSocketStateEnum.CLOSE, () => {
                this.isConnected = false
            })
        })
    }

    /**
     * Sends the data to the WebSocket server and listens for a response.
     * @private
     * @async
     * @param {string|Buffer|ArrayBuffer|Buffer[]} data - The data to send.
     * @param {Function} resolve - The resolve function for the Promise.
     * @param {Function} reject - The reject function for the Promise.
     */
    _sendMessage(data, resolve, reject) {
        this.instance.send(data, (err) => {
            if (err) {
                reject(err)
            }
        })

        this.instance.on('message', (message) => {
            resolve(message)

            if (this.isDisconnectedAfterMessage) {
                this.disconnect()
            }
        })

        this.instance.on('error', (error) => {
            reject(error)
        })
    }
}

module.exports = WebSocketClient
