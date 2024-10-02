handler_dict = {}


class HandlerDictionary:

    @staticmethod
    def add_handler_to_dict(command_type, handler):
        handler_dict[command_type] = handler
