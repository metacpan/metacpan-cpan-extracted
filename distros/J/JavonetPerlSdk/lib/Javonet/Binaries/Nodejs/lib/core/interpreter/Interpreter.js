const ConnectionType = require('../../utils/ConnectionType')
const RuntimeName = require('../../utils/RuntimeName')
const CommandDeserializer = require('../protocol/CommandDeserializer')
const CommandSerializer = require('../protocol/CommandSerializer')

/** @typedef {import('../../../../core/lib/declarations').WsConnectionData} WsConnectionData */

let _Receiver
let _Transmitter
let _TransmitterWebsocket

class Interpreter {
    handler
    /**
     *
     * @param {Command} command
     * @param {IConnectionData} connectionData
     * @returns
     */
    async executeAsync(command, connectionData) {
        try {
            let messageByteArray = new CommandSerializer().serialize(command, connectionData)
            let responseByteArray

            if (
                command.runtimeName === RuntimeName.Nodejs &&
                connectionData.connectionType === ConnectionType.IN_MEMORY
            ) {
                // lazy receiver loading
                if (!_Receiver) {
                    _Receiver = require(require.resolve('../receiver/Receiver'))
                }
                responseByteArray = _Receiver.sendCommand(messageByteArray)
            } else if (
                command.runtimeName === RuntimeName.Nodejs &&
                connectionData.connectionType === ConnectionType.WEB_SOCKET
            ) {
                try {
                    // lazy transmitter websocket loading
                    if (!_TransmitterWebsocket) {
                        _TransmitterWebsocket = require('../transmitter/TransmitterWebsocket')
                    }
                    const promise = _TransmitterWebsocket.sendCommand(messageByteArray, connectionData)
                    return promise
                        .then((_response) => {
                            if (_response) {
                                const command = new CommandDeserializer(_response).deserialize()
                                return command
                            }
                        })
                        .catch((error) => {
                            throw error
                        })
                } catch (error) {
                    console.log(error)
                }
            } else {
                // lazy transmitter loading
                if (!_Transmitter) {
                    _Transmitter = require(require.resolve('../transmitter/Transmitter'))
                }
                responseByteArray = await _Transmitter.sendCommand(messageByteArray)
            }
            return new CommandDeserializer(responseByteArray).deserialize()
            // eslint-disable-next-line no-unused-vars
        } catch (error) {
            // TODO: handle error exception log?
        }
    }

    /**
     *
     * @param {Command} command
     * @param {WsConnectionData} connectionData
     * @returns {Promise<Command>}
     */
    execute(command, connectionData) {
        try {
            let messageByteArray = new CommandSerializer().serialize(command, connectionData)
            let responseByteArray

            if (
                command.runtimeName === RuntimeName.Nodejs &&
                connectionData.connectionType === ConnectionType.IN_MEMORY
            ) {
                // lazy receiver loading
                if (!_Receiver) {
                    _Receiver = require(require.resolve('../receiver/Receiver'))
                }
                responseByteArray = _Receiver.sendCommand(messageByteArray)
            } else if (
                command.runtimeName === RuntimeName.Nodejs &&
                connectionData.connectionType === ConnectionType.WEB_SOCKET
            ) {
                // lazy transmitter websocket loading
                if (!_TransmitterWebsocket) {
                    _TransmitterWebsocket = require(require.resolve('../transmitter/TransmitterWebsocket'))
                }
                const promise = _TransmitterWebsocket.sendCommand(messageByteArray, connectionData)
                return promise
                    .then((_response) => {
                        if (_response) {
                            const command = new CommandDeserializer(_response).deserialize()
                            return command
                        }
                    })
                    .catch((error) => {
                        throw error
                    })
            } else {
                // lazy transmitter loading
                if (!_Transmitter) {
                    _Transmitter = require(require.resolve('../transmitter/Transmitter'))
                }
                responseByteArray = _Transmitter.sendCommand(messageByteArray)
            }
            return new CommandDeserializer(responseByteArray).deserialize()
            // eslint-disable-next-line no-unused-vars
        } catch (error) {
            // TODO: handle error exception log?
        }
    }

    /**
     *
     * @param {number[]} messageByteArray
     * @returns {Command}
     */
    process(messageByteArray) {
        if (!this.handler) {
            const baseHandler = require(require.resolve('../handler/Handler'))
            if (baseHandler) {
                const { Handler } = baseHandler
                this.handler = new Handler()
            }
        }
        const receivedCommand = new CommandDeserializer(messageByteArray).deserialize()
        return this.handler.handleCommand(receivedCommand)
    }
}

module.exports = Interpreter
