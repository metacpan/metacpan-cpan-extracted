from javonet.core.handler.AbstractCommandHandler import *


class SetInstanceFieldHandler(AbstractCommandHandler):

    def __init__(self):
        self._required_parameters_count = 3

    def process(self, command):
        try:
            if len(command.payload) < self._required_parameters_count:
                raise Exception("SetInstanceFieldHandler parameters mismatch!")
            instance = command.payload[0]
            field = command.payload[1]
            new_value = command.payload[2]
            try:
                setattr(instance, field, new_value)
            except AttributeError:
                fields = [field for field in dir(instance) if not callable(getattr(instance, field))]
                message = "Field {} not found in class {}. Available fields:\n".format(field, instance.__class__.__name__)
                for field in fields:
                    message += "{}\n".format(field)
                raise AttributeError(message)
            return 0
        except Exception as e:
            exc_type, exc_value = type(e), e
            new_exc = exc_type(exc_value).with_traceback(e.__traceback__)
            raise new_exc from None

