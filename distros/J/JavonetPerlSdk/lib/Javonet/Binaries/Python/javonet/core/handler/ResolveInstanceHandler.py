from javonet.core.handler.AbstractCommandHandler import *
from javonet.core.referenceCache.ReferencesCache import ReferencesCache


class ResolveInstanceHandler(AbstractCommandHandler):
    def __init__(self):
        self._required_parameters_count = 1

    def process(self, command):
        try:
            if len(command.payload) != self._required_parameters_count:
                raise Exception("ResolveInstanceHandler parameters mismatch!")

            references_cache = ReferencesCache()
            return references_cache.resolve_reference(command)
        except Exception as e:
            exc_type, exc_value = type(e), e
            new_exc = exc_type(exc_value).with_traceback(e.__traceback__)
            raise new_exc from None
