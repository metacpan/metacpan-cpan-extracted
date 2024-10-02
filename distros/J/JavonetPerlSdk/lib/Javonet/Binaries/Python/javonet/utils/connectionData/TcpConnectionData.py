import hashlib
import socket

from javonet.utils.ConnectionType import ConnectionType
from javonet.utils.connectionData.IConnectionData import IConnectionData


class TcpConnectionData(IConnectionData):

    def __init__(self, hostname: str, port: int):
        self._hostname = hostname
        self._port = port
        self._ip_address = ""
        if self._hostname == "localhost":
            self._ip_address = "127.0.0.1"
        else:
            try:
                self._ip_address = socket.gethostbyname(self._hostname)
            except socket.gaierror:
                self._ip_address = ""

    @property
    def connection_type(self):
        return ConnectionType.Tcp

    @property
    def hostname(self):
        return self._hostname

    @property
    def ip_address(self):
        return self._ip_address

    @property
    def port(self):
        return self._port

    def serialize_connection_data(self):
        address_bytes = self.__get_address_bytes()
        port_bytes = self.__get_pot_bytes()
        return [self.connection_type.value] + address_bytes + port_bytes

    def __get_address_bytes(self):
        return [int(x) for x in self._ip_address.split(".")]

    def __get_pot_bytes(self):
        return [self._port & 0xFF, self._port >> 8]

    def __eq__(self, other):
        if isinstance(other, TcpConnectionData):
            return self._ip_address == other.ip_address and self._port == other.port
        return False

    def __hash__(self):
        return int(hashlib.sha1(f"{self._ip_address}{self._port}".encode()).hexdigest(), 16)

    @hostname.setter
    def hostname(self, value):
        self._hostname = value

    @port.setter
    def port(self, value):
        self._port = value

    @ip_address.setter
    def ip_address(self, value):
        self._ip_address = value
