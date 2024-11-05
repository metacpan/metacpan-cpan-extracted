from javonet.core.delegateCache.DelegatesCache import DelegatesCache
from javonet.core.handler.AbstractCommandHandler import *


class PassDelegateHandler(AbstractCommandHandler):

    def __init__(self):
        self._required_parameters_count = 1

    def process(self, command):
        try:
            if len(command.payload) != self._required_parameters_count:
                raise Exception("ResolveInstanceHandler parameters mismatch!")

            # TO BE IMPLEMENTED
        except Exception as e:
            exc_type, exc_value = type(e), e
            new_exc = exc_type(exc_value).with_traceback(e.__traceback__)
            raise new_exc from None


