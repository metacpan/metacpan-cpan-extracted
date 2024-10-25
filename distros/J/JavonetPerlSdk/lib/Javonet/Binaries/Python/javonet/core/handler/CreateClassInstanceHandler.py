from inspect import signature

from javonet.core.handler.AbstractCommandHandler import *


class CreateClassInstanceHandler(AbstractCommandHandler):
    def __init__(self):
        self._required_parameters_count = 1

    def process(self, command):
        try:
            if len(command.payload) < self._required_parameters_count:
                raise Exception("CreateClassInstanceHandler parameters mismatch!")
            clazz = command.payload[0]
            if len(command.payload) > 1:
                method_arguments = command.payload[1:]
                return clazz(*method_arguments)
            return clazz()
        except Exception as e:
            exc_type, exc_value = type(e), e
            new_exc = exc_type(exc_value).with_traceback(e.__traceback__)
            raise new_exc from None
