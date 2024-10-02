from importlib import import_module

from javonet.core.handler.AbstractCommandHandler import AbstractCommandHandler


class GetEnumItemHandler(AbstractCommandHandler):
    def __init__(self):
        self._required_parameters_count = 3

    def process(self, command):
        try:
            if len(command.payload) < self._required_parameters_count:
                raise Exception("CreateEnumHandler parameters mismatch!")
            clazz = command.payload[0]
            enum_name = command.payload[1]
            enum_value = command.payload[2]
            try:
                enum_type = getattr(clazz, enum_name)
            except AttributeError:
                fields = [field for field in dir(clazz) if not callable(getattr(clazz, field))]
                message = "Enum {} not found in class {}. Available enums:\n".format(enum_name, clazz.__name__)
                for field in fields:
                    message += "{}\n".format(field)
                raise AttributeError(message)
            return enum_type[enum_value]
        except Exception as e:
            exc_type, exc_value = type(e), e
            new_exc = exc_type(exc_value).with_traceback(e.__traceback__)
            raise new_exc from None
