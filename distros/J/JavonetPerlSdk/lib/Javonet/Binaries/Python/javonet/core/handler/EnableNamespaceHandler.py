from javonet.core.handler.AbstractCommandHandler import AbstractCommandHandler
from javonet.core.namespaceCache.NamespaceCache import NamespaceCache


class EnableNamespaceHandler(AbstractCommandHandler):
    def __init__(self):
        self._required_parameters_count = 1

    def process(self, command):
        try:
            if len(command.payload) < self._required_parameters_count:
                raise Exception(self.__class__.__name__ + " parameters mismatch!")

            namespace_cache = NamespaceCache()

            for payload in command.payload:
                if isinstance(payload, str):
                    namespace_cache.cache_namespace(payload)
                if isinstance(payload, list):
                    for namespace_to_enable in payload:
                        namespace_cache.cache_namespace(namespace_to_enable)

            return 0

        except Exception as e:
            exc_type, exc_value = type(e), e
            new_exc = exc_type(exc_value).with_traceback(e.__traceback__)
            raise new_exc from None
