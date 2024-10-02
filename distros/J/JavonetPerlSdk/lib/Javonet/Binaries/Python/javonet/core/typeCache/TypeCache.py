import re
import types
import threading


class TypeCache(object):
    _instance = None
    type_cache = list()
    _lock = threading.Lock()

    def __new__(cls):
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super(TypeCache, cls).__new__(cls)
        return cls._instance

    def cache_type(self, type_regex):
        with self._lock:
            self.type_cache.append(type_regex)

    def is_type_cache_empty(self):
        with self._lock:
            return len(self.type_cache) == 0

    def is_type_allowed(self, type_to_check):
        with self._lock:
            if isinstance(type_to_check, types.ModuleType):
                name_to_check = type_to_check.__name__
            else:
                name_to_check = ".".join([type_to_check.__module__, type_to_check.__name__])
            for pattern in self.type_cache:
                if re.match(pattern, name_to_check):
                    return True
        return False

    def get_cached_types(self):
        with self._lock:
            return self.type_cache[:]

    def clear_cache(self):
        with self._lock:
            self.type_cache.clear()
            return 0
