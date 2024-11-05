import sys

from javonet.core.interpreter.Interpreter import Interpreter
from javonet.core.protocol.CommandSerializer import CommandSerializer
from javonet.utils.RuntimeLogger import RuntimeLogger
from javonet.utils.connectionData.InMemoryConnectionData import InMemoryConnectionData


class Receiver:

    def __init__(self):
        RuntimeLogger.print_runtime_info()
        sys.stdout.flush()
        self.connection_data = InMemoryConnectionData()

    def SendCommand(self, message_byte_array, messageByteArrayLen):
        return bytearray(CommandSerializer().serialize(Interpreter().process(message_byte_array), self.connection_data))

    def HeartBeat(self, message_byte_array, messageByteArrayLen):
        response_byte_array = bytearray(2)
        response_byte_array[0] = message_byte_array[11]
        response_byte_array[1] = message_byte_array[12] - 2
        return response_byte_array
