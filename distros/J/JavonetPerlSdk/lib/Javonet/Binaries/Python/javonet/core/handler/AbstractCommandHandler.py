from javonet.core.handler.HandlerDictionary import handler_dict
from javonet.utils.Command import Command


class AbstractCommandHandler:
    _required_parameters_count = 0

    def process(self, command):
        pass

    def handle_command(self, command):
        self.__iterate(command)
        return self.process(command)

    @staticmethod
    def __iterate(command):
        for i in range(0, len(command.payload)):
            if isinstance(command.payload[i], Command):
                command.payload[i] = handler_dict.get(command.payload[i].command_type).handle_command(
                        command.payload[i])
