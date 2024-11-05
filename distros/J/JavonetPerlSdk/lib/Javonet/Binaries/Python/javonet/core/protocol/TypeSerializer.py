import struct

from javonet.utils.Type import Type
from javonet.utils.StringEncodingMode import StringEncodingMode


class TypeSerializer:

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

    @staticmethod
    def serialize_command(command):
        length = list(bytearray(struct.pack("<i", len(command.payload))))
        return [Type.Command.value] + length + [command.runtime_name.value, command.command_type.value]

    @staticmethod
    def serialize_string(string_value):
        encoded_string_list = list(bytearray(string_value, 'utf-8'))
        length = list(bytearray(struct.pack("<i", len(encoded_string_list))))
        return [Type.JavonetString.value] + [StringEncodingMode.UTF8.value] + length + encoded_string_list

    @staticmethod
    def serialize_int(int_value):
        encoded_int_list = list(bytearray(struct.pack("<i", int_value)))
        length = len(encoded_int_list)
        return [Type.JavonetInteger.value, length] + encoded_int_list
    
    @staticmethod
    def serialize_bool(bool_value):
        encoded_bool_list = list(bytearray(struct.pack("?", bool_value)))
        length = len(encoded_bool_list)
        return [Type.JavonetBoolean.value, length] + encoded_bool_list
    
    @staticmethod
    def serialize_float(float_value):
        encoded_float_list = list(bytearray(struct.pack("<f", float_value)))
        length = len(encoded_float_list)
        return [Type.JavonetFloat.value, length] + encoded_float_list

    @staticmethod
    def serialize_byte(bytes_value):
        encoded_byte_list = list(bytearray(struct.pack("<B", bytes_value)))
        length = len(encoded_byte_list)
        return [Type.JavonetByte.value, length] + encoded_byte_list
    
    @staticmethod
    def serialize_char(char_value):
        encoded_char_list = list(bytearray(struct.pack("<b", char_value)))
        length = len(encoded_char_list)
        return [Type.JavonetChar.value, length] + encoded_char_list

    @staticmethod
    def serialize_longlong(longlong_value):
        encoded_longlong_list = list(bytearray(struct.pack("<q", longlong_value)))
        length = len(encoded_longlong_list)
        return [Type.JavonetLongLong.value, length] + encoded_longlong_list

    @staticmethod
    def serialize_double(double_value):
        encoded_double_list = list(bytearray(struct.pack("<d", double_value)))
        length = len(encoded_double_list)
        return [Type.JavonetDouble.value, length] + encoded_double_list

    @staticmethod
    def serialize_ullong(unsigned_longlong_value):
        encoded_unsignedlonglong_list = list(bytearray(struct.pack("<Q", unsigned_longlong_value)))
        length = len(encoded_unsignedlonglong_list)
        return [Type.JavonetUnsignedLongLong.value, length] + encoded_unsignedlonglong_list

    @staticmethod
    def serialize_uint(unsigned_int_value):
        encoded_unsigned_int_list = list(bytearray(struct.pack("<I", unsigned_int_value)))
        length = len(encoded_unsigned_int_list)
        return [Type.JavonetUnsignedInteger.value, length] + encoded_unsigned_int_list

    @staticmethod
    def serialize_none():
        return [Type.JavonetNoneType.value, 1, 0]
