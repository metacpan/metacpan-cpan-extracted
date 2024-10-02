import re
import types
import threading


class NamespaceCache(object):
    _instance = None
    namespace_cache = list()
    _lock = threading.Lock()

    def __new__(cls):
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super(NamespaceCache, cls).__new__(cls)
        return cls._instance

    def cache_namespace(self, namespace_regex):
        with self._lock:
            self.namespace_cache.append(namespace_regex)

    def is_namespace_cache_empty(self):
        with self._lock:
            return len(self.namespace_cache) == 0

    def is_type_allowed(self, type_to_check):
        with self._lock:
            for pattern in self.namespace_cache:
                if isinstance(type_to_check, types.ModuleType):
                    if re.match(pattern, type_to_check.__name__):
                        return True
                else:
                    if re.match(pattern, type_to_check.__module__):
                        return True
        return False

    def get_cached_namespaces(self):
        with self._lock:
            return self.namespace_cache[:]

    def clear_cache(self):
        with self._lock:
            self.namespace_cache.clear()
            return 0
