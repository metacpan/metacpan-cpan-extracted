from javonet.utils.ConnectionType import ConnectionType
from javonet.utils.connectionData.IConnectionData import IConnectionData


class InMemoryConnectionData(IConnectionData):
    @property
    def connection_type(self):
        return ConnectionType.InMemory

    @property
    def hostname(self):
        return ""

    def serialize_connection_data(self):
        return [self.connection_type.value, 0, 0, 0, 0, 0, 0]

    def __eq__(self, other):
        return isinstance(other, InMemoryConnectionData)

    def __hash__(self):
        hash_code = 593727026
        hash_code = hash_code * -1521134295 + hash(self.connection_type)
        return hash_code
