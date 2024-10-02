from javonet.core.handler.AbstractCommandHandler import *


class GetStaticFieldHandler(AbstractCommandHandler):

    def __init__(self):
        self._required_parameters_count = 2

    def process(self, command):
        try:
            if len(command.payload) != self._required_parameters_count:
                raise Exception("GetStaticFieldHandler parameters mismatch!")
            clazz = command.payload[0]
            field = command.payload[1]
            try:
                value = getattr(clazz, field)
            except:
                fields = [field for field in dir(clazz) if not callable(getattr(clazz, field))]
                message = "Field {} not found in class {}. Available fields:\n".format(field, clazz.__name__)
                for field in fields:
                    message += "{}\n".format(field)
                raise AttributeError(message)
            return value
        except Exception as e:
            exc_type, exc_value = type(e), e
            new_exc = exc_type(exc_value).with_traceback(e.__traceback__)
            raise new_exc from None
