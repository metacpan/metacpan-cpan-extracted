from javonet.core.protocol.TypeSerializer import TypeSerializer
from javonet.utils.Command import Command
from javonet.utils.RuntimeName import RuntimeName
from javonet.utils.connectionData.IConnectionData import IConnectionData


class CommandSerializer:
    buffer = []

    def serialize(self, root_command: Command, connection_data: IConnectionData, runtime_version=0):
        self.insert_into_buffer([root_command.runtime_name.value, runtime_version])
        self.insert_into_buffer(connection_data.serialize_connection_data())
        self.insert_into_buffer([RuntimeName.python.value, root_command.command_type.value])
        self.serialize_recursively(root_command)
        return self.buffer

    def serialize_recursively(self, command):
        for item in command.get_payload():
            if isinstance(item, Command):
                self.insert_into_buffer(TypeSerializer.serialize_command(item))
                self.serialize_recursively(item)
            else:
                self.insert_into_buffer(TypeSerializer.serialize_primitive(item))

        return

    def insert_into_buffer(self, arguments):
        self.buffer = self.buffer + arguments
