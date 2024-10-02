from javonet.core.handler.AbstractCommandHandler import AbstractCommandHandler

class ArrayGetSizeHandler(AbstractCommandHandler):
    def __init__(self):
        self._required_parameters_count = 1

    def process(self, command):
        try:
            if len(command.payload) != self._required_parameters_count:
                raise Exception("ArrayGetSizeHandler parameters mismatch!")

            array = command.payload[0]
            size = 1
            while(isinstance(array, list)):
                size = size * len(array)
                array = array[0]

            return size


        except Exception as e:
            exc_type, exc_value = type(e), e
            new_exc = exc_type(exc_value).with_traceback(e.__traceback__)
            raise new_exc from None
