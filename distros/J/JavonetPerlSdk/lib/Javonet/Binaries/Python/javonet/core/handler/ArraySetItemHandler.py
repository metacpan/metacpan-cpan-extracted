from javonet.core.handler.AbstractCommandHandler import AbstractCommandHandler


class ArraySetItemHandler(AbstractCommandHandler):
    def __init__(self):
        self._required_parameters_count = 3

    def process(self, command):
        try:
            if len(command.payload) < self._required_parameters_count:
                raise Exception("ArraySetItemHandler parameters mismatch!")

            array = command.payload[0]

            value = command.payload[2]
            if isinstance(command.payload[1], list):
                indexes = command.payload[1]
            else:
                indexes = [command.payload[1]]

            if isinstance(command.payload[0], dict):
                array[indexes[0]] = value

            # one-dimensional array
            if len(indexes) == 1:
                array[indexes[0]] = value
            # multi-dimensional array
            else:
                for i in range((len(indexes)-1)):
                    array = array[indexes[i]]

                array[indexes[-1]] = value

            return 0

        except Exception as e:
            exc_type, exc_value = type(e), e
            new_exc = exc_type(exc_value).with_traceback(e.__traceback__)
            raise new_exc from None
