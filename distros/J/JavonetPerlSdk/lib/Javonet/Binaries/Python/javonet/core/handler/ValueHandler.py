from javonet.core.handler.AbstractCommandHandler import AbstractCommandHandler


class ValueHandler(AbstractCommandHandler):
    def process(self, command):
        return command.payload[0]
