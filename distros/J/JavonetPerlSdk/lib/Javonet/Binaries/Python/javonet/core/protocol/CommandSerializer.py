from collections import deque
from typing import Deque

from javonet.core.protocol.TypeSerializer import TypeSerializer
from javonet.utils.Command import Command
from javonet.utils.RuntimeName import RuntimeName
from javonet.utils.connectionData.IConnectionData import IConnectionData


class CommandSerializer:
    byte_buffer = []

    def serialize(self, root_command: Command, connection_data: IConnectionData, runtime_version=0):
        queue: Deque[Command] = deque()
        queue.append(root_command)
        self.insert_into_buffer([root_command.runtime_name.value, runtime_version])
        self.insert_into_buffer(connection_data.serialize_connection_data())
        self.insert_into_buffer([RuntimeName.python.value, root_command.command_type.value])
        return self.serialize_recursively(queue)

    @staticmethod
    def serialize_primitive(payload_item):
        if payload_item is None:
            return TypeSerializer.serialize_none()
        if isinstance(payload_item, bool):
            return TypeSerializer.serialize_bool(payload_item)
        elif isinstance(payload_item, int):
            if payload_item in range(-2 ** 31, 2 ** 31):
                return TypeSerializer.serialize_int(payload_item)
            elif payload_item in range(-2 ** 63, 2 ** 63):
                return TypeSerializer.serialize_longlong(payload_item)
            else:
                return TypeSerializer.serialize_ullong(payload_item)
        elif isinstance(payload_item, float):
            return TypeSerializer.serialize_double(payload_item)
        elif isinstance(payload_item, str):
            return TypeSerializer.serialize_string(payload_item)
        else:
            raise Exception("Python: Type serialization not supported for type: " + payload_item)

    def insert_into_buffer(self, arguments):
        self.byte_buffer = self.byte_buffer + arguments

    def serialize_recursively(self, queue):
        if not queue:
            return self.byte_buffer
        command = queue.pop()
        queue.append(command.drop_first_payload_argument())
        if len(command.get_payload()) > 0:
            if isinstance(command.get_payload()[0], Command):
                inner_command = command.get_payload()[0]
                self.insert_into_buffer(TypeSerializer.serialize_command(inner_command))
                queue.append(inner_command)
            else:
                result = self.serialize_primitive(command.get_payload()[0])
                self.insert_into_buffer(result)
            return self.serialize_recursively(queue)
        else:
            queue.pop()

        return self.serialize_recursively(queue)
