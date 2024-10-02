from enum import Enum

from javonet.core.handler.AbstractCommandHandler import AbstractCommandHandler


class GetEnumValueHandler(AbstractCommandHandler):
    def __init__(self):
        self._required_parameters_count = 1

    def process(self, command):
        try:
            if len(command.payload) < self._required_parameters_count:
                raise Exception("CreateEnumHandler parameters mismatch!")
            enum_object = command.payload[0]
            if isinstance(enum_object, Enum):
                return enum_object.value
            else:
                raise Exception("Argument is not enumerable")
        except Exception as e:
            exc_type, exc_value = type(e), e
            new_exc = exc_type(exc_value).with_traceback(e.__traceback__)
            raise new_exc from None
