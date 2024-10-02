from javonet.core.handler.AbstractCommandHandler import AbstractCommandHandler


class ArrayGetItemHandler(AbstractCommandHandler):
    def __init__(self):
        self._required_parameters_count = 2

    def process(self, command):
        try:
            if len(command.payload) < self._required_parameters_count:
                raise Exception("ArrayGetItemHandler parameters mismatch!")

            array = command.payload[0]
            if isinstance(command.payload[1], list):
                indexes = command.payload[1]
            else:
                indexes = command.payload[1:]

            array_copy = array.copy()
            for i in indexes:
                array_copy = array_copy[i]
            return array_copy

        except Exception as e:
            exc_type, exc_value = type(e), e
            new_exc = exc_type(exc_value).with_traceback(e.__traceback__)
            raise new_exc from None
