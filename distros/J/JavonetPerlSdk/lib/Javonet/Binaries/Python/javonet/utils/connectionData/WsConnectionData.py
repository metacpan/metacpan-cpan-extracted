import hashlib

from javonet.utils.ConnectionType import ConnectionType
from javonet.utils.connectionData.IConnectionData import IConnectionData


class WsConnectionData(IConnectionData):

    def __init__(self, hostname: str):
        self._hostname = hostname
    @property
    def connection_type(self):
        return ConnectionType.WebSocket

    @property
    def hostname(self):
        return self._hostname

    def serialize_connection_data(self):
        return [self.connection_type.value, 0, 0, 0, 0, 0, 0]

    def __eq__(self, other):
        return isinstance(other, WsConnectionData) and self._hostname == other.hostname

    def __hash__(self):
        return int(hashlib.sha1(f"{self.hostname}".encode()).hexdigest(), 16)

    @hostname.setter
    def hostname(self, value):
        self._hostname = value
