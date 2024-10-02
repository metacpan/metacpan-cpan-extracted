import struct

from javonet.utils import Command, CommandType, RuntimeName
from javonet.utils.StringEncodingMode import StringEncodingMode


class TypeDeserializer:

    @staticmethod
    def deserialize_command(encoded_command ):
        return Command(RuntimeName(encoded_command[0]), CommandType(encoded_command[1]), [])

    @staticmethod
    def deserialize_string(string_encoding_mode, encoded_string):
        if string_encoding_mode == StringEncodingMode.ASCII:
            return bytearray(encoded_string).decode('ascii')
        if string_encoding_mode == StringEncodingMode.UTF8:
            return bytearray(encoded_string).decode('utf-8')
        if string_encoding_mode == StringEncodingMode.UTF16:
            return bytearray(encoded_string).decode('utf-16')
        if string_encoding_mode == StringEncodingMode.UTF32:
            return bytearray(encoded_string).decode('utf-32')

        raise IndexError("String encoding mode out of range")

    @staticmethod
    def deserialize_int(encoded_int):
        return struct.unpack("<i", bytearray(encoded_int))[0]
    
    @staticmethod
    def deserialize_bool(encoded_bool):
        return struct.unpack("<?", bytearray(encoded_bool))[0]
    
    @staticmethod
    def deserialize_float(encoded_float):
        return struct.unpack("<f", bytearray(encoded_float))[0]

    @staticmethod
    def deserialize_byte(encoded_byte):
        return struct.unpack("<B", bytearray(encoded_byte))[0]
    
    @staticmethod
    def deserialize_char(encoded_char):
        return struct.unpack("<b", bytearray(encoded_char))[0]

    @staticmethod
    def deserialize_longlong(encoded_longlong):
        return struct.unpack("<q", bytearray(encoded_longlong))[0]

    @staticmethod
    def deserialize_double(encoded_double):
        return struct.unpack("<d", bytearray(encoded_double))[0]

    @staticmethod
    def deserialize_ullong(encoded_unsigned_longlong):
        return struct.unpack("<Q", bytearray(encoded_unsigned_longlong))[0]

    @staticmethod
    def deserialize_uint(encoded_unsigned_int):
        return struct.unpack("<I", bytearray(encoded_unsigned_int))[0]

    @staticmethod
    def deserialize_none(encoded_none):
        return None
