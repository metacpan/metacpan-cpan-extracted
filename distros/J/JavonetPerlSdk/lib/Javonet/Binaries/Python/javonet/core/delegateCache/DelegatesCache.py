import uuid
import threading
from javonet.utils.CommandType import CommandType


class DelegatesCache(object):
    _instance = None
    delegates_cache = dict()
    _lock = threading.Lock()  # Initialize a lock object

    def __new__(cls):
        with cls._lock:
            if cls._instance is None:
                cls._instance = super(DelegatesCache, cls).__new__(cls)
        return cls._instance

    def cache_delegate(self, object_delegate):
        with self._lock:
            uuid_ = str(uuid.uuid4())
            self.delegates_cache[uuid_] = object_delegate
            return uuid_

    def resolve_delegate(self, command):
        if command.command_type != CommandType.Reference:
            raise Exception(
                "Failed to find delegate")
        with self._lock:
            try:
                return self.delegates_cache[command.payload[0]]
            except KeyError:
                raise Exception("Object not found in delegates")

    def delete_delegate(self, delegate_guid):
        with self._lock:
            try:
                del self.delegates_cache[delegate_guid]
                return 0
            except KeyError:
                raise Exception("Object not found in delegates")
