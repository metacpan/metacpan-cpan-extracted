from javonet.core.handler.AbstractCommandHandler import AbstractCommandHandler
from javonet.core.typeCache.TypeCache import TypeCache


class EnableTypeHandler(AbstractCommandHandler):
    def __init__(self):
        self._required_parameters_count = 1

    def process(self, command):
        try:
            if len(command.payload) < self._required_parameters_count:
                raise Exception(self.__class__.__name__ + " parameters mismatch!")

            type_cache = TypeCache()

            for payload in command.payload:
                if isinstance(payload, str):
                    type_cache.cache_type(payload)
                if isinstance(payload, list):
                    for type_to_enable in payload:
                        type_cache.cache_type(type_to_enable)

            return 0

        except Exception as e:
            exc_type, exc_value = type(e), e
            new_exc = exc_type(exc_value).with_traceback(e.__traceback__)
            raise new_exc from None
