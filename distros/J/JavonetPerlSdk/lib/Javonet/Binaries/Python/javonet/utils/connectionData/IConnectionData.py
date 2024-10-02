from abc import ABC, abstractmethod
from javonet.utils.ConnectionType import ConnectionType


class IConnectionData(ABC):
    @property
    @abstractmethod
    def connection_type(self):
        pass

    @property
    @abstractmethod
    def hostname(self):
        pass

    @abstractmethod
    def serialize_connection_data(self):
        pass
