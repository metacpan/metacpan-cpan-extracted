from importlib import import_module

from javonet.core.handler.AbstractCommandHandler import AbstractCommandHandler
from javonet.core.namespaceCache.NamespaceCache import NamespaceCache
from javonet.core.typeCache.TypeCache import TypeCache


class GetTypeHandler(AbstractCommandHandler):
    def __init__(self):
        self._required_parameters_count = 1
        self.namespace_cache = NamespaceCache()
        self.type_cache = TypeCache()

    def process(self, command):
        try:
            if len(command.payload) < self._required_parameters_count:
                raise Exception(self.__class__.__name__ + " parameters mismatch!")

            type_to_return = self._get_type_from_payload(command)

            if type_to_return is None:
                raise Exception(f"Type {command.payload[0]} not found")

            if ((
                    self.namespace_cache.is_namespace_cache_empty() and self.type_cache.is_type_cache_empty()) or  # both caches are empty
                    self.namespace_cache.is_type_allowed(type_to_return) or  # namespace is allowed
                    self.type_cache.is_type_allowed(type_to_return)  # type is allowed
            ):
                pass  # continue - type is allowed
            else:
                allowed_namespaces = ", ".join(self.namespace_cache.get_cached_namespaces())
                allowed_types = ", ".join(self.type_cache.get_cached_types())
                raise Exception(
                    f"Type {type_to_return.__name__} not allowed. \nAllowed namespaces: {allowed_namespaces}\nAllowed types: {allowed_types}")

            return type_to_return

        except Exception as e:
            exc_type, exc_value = type(e), e
            new_exc = exc_type(exc_value).with_traceback(e.__traceback__)
            raise new_exc from None

    def _get_type_from_payload(self, command):
        if len(command.payload) == 1:
            type_name = command.payload[0].split(".")
            if len(type_name) == 1:
                return import_module(type_name[0])
            else:
                return self._get_type_from_nested_payload(type_name)
        else:
            return self._get_type_from_nested_payload(command.payload)

    def _get_type_from_nested_payload(self, payload):
        module_name = ".".join(payload[:-1])
        class_name = payload[-1]
        loaded_module = import_module(module_name)
        return getattr(loaded_module, class_name)
