const { Handler } = require('../handler/Handler')
const CommandSerializer = require('../protocol/CommandSerializer')
const CommandDeserializer = require('../protocol/CommandDeserializer')
const Runtime = require("../../utils/RuntimeName");
const ConnectionType = require('../../utils/ConnectionType');

let Transmitter
let Receiver

class Interpreter {
    handler = new Handler()

    async executeAsync(command, connectionData) {
        try {
            const messageByteArray = new CommandSerializer().serialize(command, connectionData)

            if (connectionData.connectionType === ConnectionType.WEB_SOCKET) {
                const { WebSocketClient } = require("../webSocketClient/WebSocketClient");
                const wsClient = new WebSocketClient(connectionData.hostname, null)

                const responseByteArray = await wsClient.send(messageByteArray)
                return new CommandDeserializer(responseByteArray).deserialize()
            }
            else {
                return this.execute(command, connectionData)
            }
        } catch (error) {
            // TODO: handle error exception log?
        }
    }
    
    execute(command, connectionData) {
        try {
            let messageByteArray = new CommandSerializer().serialize(command, connectionData)
            let responseByteArray
            
            if (command.runtimeName === Runtime.Nodejs && connectionData.connectionType === ConnectionType.IN_MEMORY)
            {
                // lazy receiver loading
                if (!Receiver) {
                    Receiver = require('../receiver/Receiver')
                }
                responseByteArray = Receiver.sendCommand(messageByteArray)

            }
            else {
                // lazy transmitter loading
                if (!Transmitter) {
                    Transmitter = require('../transmitter/Transmitter')
                }
                responseByteArray = Transmitter.sendCommand(messageByteArray)
            }
            return new CommandDeserializer(responseByteArray).deserialize()
        } catch (error) {
            // TODO: handle error exception log?
        }
    }

    process(messageByteArray) {
        let receivedCommand = new CommandDeserializer(messageByteArray).deserialize()
        return this.handler.handleCommand(receivedCommand)
    }
}

module.exports = Interpreter
