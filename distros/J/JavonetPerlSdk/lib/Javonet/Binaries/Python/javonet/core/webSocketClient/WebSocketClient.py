import struct
from websockets.sync.client import connect

from javonet.utils.connectionData.WsConnectionData import WsConnectionData


class WebSocketClient:
    _instance = None
    clients = dict()

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(WebSocketClient, cls).__new__(cls)
        return cls._instance

    def add_or_get_client(self, connection_data: WsConnectionData):
        if connection_data.hostname in self.clients:
            return self.clients[connection_data.hostname]
        else:
            self.clients[connection_data.hostname] = connect(connection_data.hostname)
            return self.clients[connection_data.hostname]

    def send_message(self, connection_data: WsConnectionData, serialized_command):
        byte_array = struct.pack("B" * len(serialized_command), *serialized_command)
        return self.send(connection_data, byte_array)

    def send(self, connection_data: WsConnectionData, byte_array):
        websocket = self.add_or_get_client(connection_data)
        websocket.send(byte_array)
        response = websocket.recv()
        return response
