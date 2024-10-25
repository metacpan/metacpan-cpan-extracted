require_relative 'type_deserializer'
require_relative '../../utils/type'
require_relative '../../utils/command'
require_relative '../../utils/string_encoding_mode'

class CommandDeserializer

  def initialize(buffer)
    @buffer = buffer
    @byte_array_len = buffer.length
    @command = Command.new(buffer[0], buffer[10], [])
    @position = 11
  end

  def is_at_end
    @position == @byte_array_len
  end

  def deserialize
    until is_at_end
      @command = @command.add_arg_to_payload(read_object(@buffer[@position]))
    end
    @command
  end

  # def copy_from(self, bytes_to_copy, elements_to_skip):
  #     size = len(bytes_to_copy) - elements_to_skip
  #     new_byte_array = bytes_to_copy[size]
  #     return new_byte_array

  def read_object(type_num)
    case type_num
    when Type::COMMAND
      return self.read_command
    when Type::JAVONET_STRING
      return self.read_string
    when Type::JAVONET_INTEGER
      return self.read_int
    when Type::JAVONET_BOOLEAN
      return self.read_bool
    when Type::JAVONET_FLOAT
      return self.read_float
    when Type::JAVONET_BYTE
      return self.read_byte
    when Type::JAVONET_CHAR
      return self.read_char
    when Type::JAVONET_LONG_LONG
      return self.read_longlong
    when Type::JAVONET_DOUBLE
      return self.read_double
    when Type::JAVONET_UNSIGNED_LONG_LONG
      return self.read_ullong
    when Type::JAVONET_UNSIGNED_INTEGER
      return self.read_uint
    when Type::JAVONET_NULL
      return self.read_nil
    else
      raise Exception.new("Type #{type_num} not supported in command deserializer")
    end
  end

  def read_command
    p = @position
    number_of_elements_in_payload = TypeDeserializer.deserialize_int(@buffer[p + 1..p + 4])
    runtime = @buffer[p + 5]
    command_type = @buffer[p + 6]
    @position += 7
    return_command = Command.new(runtime, command_type, [])
    read_command_recursively(number_of_elements_in_payload, return_command)
  end

  def read_command_recursively(number_of_elements_in_payload_left, cmd)
    if number_of_elements_in_payload_left == 0
      cmd
    else
      p = @position
      cmd = cmd.add_arg_to_payload(self.read_object(@buffer[p]))
      read_command_recursively(number_of_elements_in_payload_left - 1, cmd)
    end
  end

  def read_string
    p = @position
    string_encoding_mode = @buffer[p + 1]
    size = TypeDeserializer.deserialize_int(@buffer[p + 2..p + 5])
    @position += 6
    p = @position
    @position += size
    TypeDeserializer.deserialize_string(string_encoding_mode, @buffer[p..p + size - 1])
  end

  def read_int
    size = 4
    @position += 2
    p = @position
    @position += size
    TypeDeserializer.deserialize_int(@buffer[p..p + size - 1])
  end

  def read_bool
    size = 1
    @position += 2
    p = @position
    @position += size
    TypeDeserializer.deserialize_bool(@buffer[p..p + size])
  end

  def read_float
    size = 4
    @position += 2
    p = @position
    @position += size
    TypeDeserializer.deserialize_float(@buffer[p..p + size - 1])
  end

  def read_byte
    size = 1
    @position += 2
    p = @position
    @position += size
    TypeDeserializer.deserialize_byte(@buffer[p..p + size])
  end

  def read_char
    size = 1
    @position += 2
    p = @position
    @position += size
    TypeDeserializer.deserialize_char(@buffer[p..p + size])
  end

  def read_longlong
    size = 8
    @position += 2
    p = @position
    @position += size
    TypeDeserializer.deserialize_longlong(@buffer[p..p + size - 1])
  end

  def read_double
    size = 8
    @position += 2
    p = @position
    @position += size
    TypeDeserializer.deserialize_double(@buffer[p..p + size - 1])
  end

  def read_ullong
    size = 8
    @position += 2
    p = @position
    @position += size
    TypeDeserializer.deserialize_ullong(@buffer[p..p + size - 1])
  end

  def read_uint
    size = 4
    @position += 2
    p = @position
    @position += size
    TypeDeserializer.deserialize_uint(@buffer[p..p + size - 1])
  end

  def read_nil
    size = 1
    @position += 2
    p = @position
    @position += size
    TypeDeserializer.deserialize_nil(@buffer[p..p + size])
  end
end