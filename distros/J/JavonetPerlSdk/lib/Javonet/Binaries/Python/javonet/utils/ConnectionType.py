from enum import Enum


class ConnectionType(Enum):
    InMemory = 0
    Tcp = 1
    WebSocket = 2
