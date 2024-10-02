from javonet.utils.CommandType import CommandType


class Command:

    def __init__(self, runtime_name, command_type, payload):
        self.runtime_name = runtime_name
        self.command_type = command_type
        self.payload = payload

    def get_payload(self):
        return self.payload

    @staticmethod
    def create_response(response, runtime_name):
        return Command(runtime_name, CommandType.Value, [response])

    @staticmethod
    def create_reference(guid, runtime_name):
        return Command(runtime_name, CommandType.Reference, [guid])

    @staticmethod
    def create_array_response(array, runtime_name):
        return Command(runtime_name, CommandType.Array, array)

    def drop_first_payload_argument(self):
        payload_args = []
        payload_args.extend(self.payload)
        if len(payload_args) != 0:
            payload_args.pop(0)
        return Command(self.runtime_name, self.command_type, payload_args)

    def add_arg_to_payload(self, argument):
        merged_payload = self.payload + [argument]
        return Command(self.runtime_name, self.command_type, merged_payload)

    def prepend_arg_to_payload(self, current_command):
        if current_command is None:
            return Command(self.runtime_name, self.command_type, self.payload)
        else:
            return Command(self.runtime_name, self.command_type, [current_command] + self.payload)

    def to_string(self):
        return 'Target runtime: ' + str(self.runtime_name) + ' Command type: ' + str(
            self.command_type) + ' Payload: ' + str(self.payload)

    def __eq__(self, element):
        self.is_equal = False
        if self is element:
            self.is_equal = True
        if element is None or self.__class__ != element.__class__:
            self.is_equal = False
        if self.command_type is element.command_type and self.runtime_name is element.runtime_name:
            self.is_equal = True
        if len(self.payload) == len(element.payload):
            i = 0
            array_item_equal = False
            for payload_item in self.payload:
                if payload_item.__eq__(element.payload[i]):
                    array_item_equal = True
                else:
                    array_item_equal = False
                i += 1
            self.is_equal = array_item_equal
        else:
            self.is_equal = False
        return self.is_equal
