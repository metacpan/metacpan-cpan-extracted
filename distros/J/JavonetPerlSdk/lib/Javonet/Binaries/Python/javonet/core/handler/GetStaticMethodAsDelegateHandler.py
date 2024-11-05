from javonet.core.handler.AbstractCommandHandler import *


class GetStaticMethodAsDelegateHandler(AbstractCommandHandler):

    def __init__(self):
        self._required_parameters_count = 2

    def process(self, command):
        try:
            if len(command.payload) < self._required_parameters_count:
                raise Exception("InvokeStaticMethod Parameters mismatch!")

            clazz = command.payload[0]
            try:
                method = getattr(clazz, command.payload[1])
            except AttributeError:
                methods = [method for method in dir(clazz) if callable(getattr(clazz, method))]
                message = "Method {} not found in class {}. Available methods:\n".format(command.payload[1],
                                                                                         clazz.__name__)
                for method in methods:
                    message += "{}\n".format(method)
                raise AttributeError(message)

            return method
        except Exception as e:
            exc_type, exc_value = type(e), e
            new_exc = exc_type(exc_value).with_traceback(e.__traceback__)
            raise new_exc from None


