require_relative '../../utils/string_encoding_mode'

class TypeDeserializer

  def self.deserialize_command(command_byte_array)
    Command.new(RuntimeName(command_byte_array[0]), CommandType(command_byte_array[1]), [])
  end

  def self.deserialize_string(string_encoding_mode, encoded_string)
    case string_encoding_mode
    when StringEncodingMode::ASCII
      encoded_string.pack('C*').force_encoding("US-ASCII").encode("UTF-8")
    when StringEncodingMode::UTF8
      encoded_string.pack("C*").force_encoding("UTF-8").encode("UTF-8")
    when StringEncodingMode::UTF16
      encoded_string.pack("C*").force_encoding("UTF-16LE").encode("UTF-8")
    when StringEncodingMode::UTF32
      encoded_string.pack("C*").force_encoding("UTF-32").encode("UTF-8")
    else
      raise "Argument out of range in deserialize_string"
    end

  end

  def self.deserialize_int(encoded_int)
    encoded_int.map(&:chr).join.unpack('i').first
  end

  def self.deserialize_bool(encoded_bool)
    encoded_bool[0] == 1
  end

  def self.deserialize_float(encoded_float)
    encoded_float.map(&:chr).join.unpack('f').first
  end

  def self.deserialize_byte(encoded_byte)
    encoded_byte[0]
  end

  def self.deserialize_char(encoded_char)
    encoded_char[0].ord
  end

  def self.deserialize_longlong(encoded_long)
    encoded_long.map(&:chr).join.unpack('q').first
  end

  def self.deserialize_double(encoded_double)
    encoded_double.map(&:chr).join.unpack('d').first
  end

  def self.deserialize_ullong(encoded_ullong)
    encoded_ullong.map(&:chr).join.unpack('Q').first
  end

  def self.deserialize_uint(encoded_uint)
    encoded_uint.map(&:chr).join.unpack('I').first
  end

  def self.deserialize_nil(encoded_nil)
    nil
  end

end
