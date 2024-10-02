import uuid
import threading
from javonet.utils.CommandType import CommandType


class ReferencesCache(object):
    _instance = None
    references_cache = dict()
    _lock = threading.Lock()  # Initialize a lock object

    def __new__(cls):
        with cls._lock:
            if cls._instance is None:
                cls._instance = super(ReferencesCache, cls).__new__(cls)
        return cls._instance

    def cache_reference(self, object_reference):
        with self._lock:
            uuid_ = str(uuid.uuid4())
            self.references_cache[uuid_] = object_reference
            return uuid_

    def resolve_reference(self, command):
        if command.command_type != CommandType.Reference:
            raise Exception(
                "Trying to dereference Python command with command_type: " + str(command.command_type))
        with self._lock:
            try:
                return self.references_cache[command.payload[0]]
            except KeyError:
                raise Exception("Object not found in references")

    def delete_reference(self, reference_guid):
        with self._lock:
            try:
                del self.references_cache[reference_guid]
                return 0
            except KeyError:
                raise Exception("Object not found in references")
