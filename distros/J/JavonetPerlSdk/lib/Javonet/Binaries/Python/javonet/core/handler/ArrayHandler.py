from javonet.core.handler.AbstractCommandHandler import AbstractCommandHandler


class ArrayHandler(AbstractCommandHandler):
    def process(self, command):
        try:
            processedArray = command.payload
            return processedArray

        except Exception as e:
            exc_type, exc_value = type(e), e
            new_exc = exc_type(exc_value).with_traceback(e.__traceback__)
            raise new_exc from None
