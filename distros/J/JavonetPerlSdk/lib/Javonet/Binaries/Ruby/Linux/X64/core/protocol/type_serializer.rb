require_relative '../../utils/type'
require_relative '../../utils/string_encoding_mode'

class TypeSerializer

  def self.serialize_command(command)
    length = [command.payload.length].pack("i").bytes
    return [Type::COMMAND] + length + [command.runtime_name, command.command_type]
  end

  def self.serialize_string(string_value)
    encoded_string_list = string_value.bytes
    length = [encoded_string_list.length].pack("i").bytes
    return [Type::JAVONET_STRING, StringEncodingMode::UTF8] + length + encoded_string_list
  end

  def self.serialize_int(int_value)
    encoded_int_list = [int_value].pack("i").bytes
    length = encoded_int_list.length
    return [Type::JAVONET_INTEGER, length] + encoded_int_list
  end

  def self.serialize_bool(bool_value)
    encoded_bool_list = bool_value ? [1] : [0]
    length = encoded_bool_list.length
    return [Type::JAVONET_BOOLEAN, length] + encoded_bool_list
  end

  def self.serialize_float(float_value)
    encoded_float_list = [float_value].pack("f").bytes
    length = encoded_float_list.length
    return [Type::JAVONET_FLOAT, length] + encoded_float_list
  end

  def self.serialize_byte(byte_value)
    encoded_byte_list = [byte_value].pack("c").bytes
    length = encoded_byte_list.length
    return [Type::JAVONET_BYTE, length] + encoded_byte_list
  end

  def self.serialize_char(char_value)
    encoded_char_list = [char_value].pack("c").bytes
    length = encoded_char_list.length
    return [Type::JAVONET_CHAR, length] + encoded_char_list
  end

  def self.serialize_longlong(longlong_value)
    encoded_longlong_list = [longlong_value].pack("q").bytes
    length = encoded_longlong_list.length
    return [Type::JAVONET_LONG_LONG, length] + encoded_longlong_list
  end

  def self.serialize_double(double_value)
    encoded_double_list = [double_value].pack("d").bytes
    length = encoded_double_list.length
    return [Type::JAVONET_DOUBLE, length] + encoded_double_list
  end

  def self.serialize_uint(uint_value)
    encoded_uint_list = [uint_value].pack("I").bytes
    length = encoded_uint_list.length
    return [Type::JAVONET_UNSIGNED_INTEGER, length] + encoded_uint_list
  end

  def self.serialize_ullong(ullong_value)
    encoded_ullong_list = [ullong_value].pack("Q").bytes
    length = encoded_ullong_list.length
    return [Type::JAVONET_UNSIGNED_LONG_LONG, length] + encoded_ullong_list
  end

  def self.serialize_nil
    return [Type::JAVONET_NULL, 1, 0]
  end

end
