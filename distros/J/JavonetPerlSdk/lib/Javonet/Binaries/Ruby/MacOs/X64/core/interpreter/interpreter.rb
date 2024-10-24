require_relative '../protocol/command_serializer'
require_relative '../protocol/command_deserializer'
require_relative '../handler/handler'

class Interpreter
  def execute(command, connection_type, tcp_connection_data)

    command_serializer = CommandSerializer.new
    message_byte_array = command_serializer.serialize(command, connection_type, tcp_connection_data)
    if command.runtime_name == RuntimeName::RUBY && connection_type == ConnectionType::IN_MEMORY
      require_relative '../receiver/receiver'
      response_byte_array = Receiver.new.send_command(message_byte_array, message_byte_array.length)
    else
      require_relative '../transmitter/transmitter'
      response_byte_array = Transmitter.send_command(message_byte_array, message_byte_array.length)
    end

    command_deserializer = CommandDeserializer.new(response_byte_array,response_byte_array.length)
    command_deserializer.deserialize
  end

  def process(byte_array, byte_array_len)
    command_deserializer = CommandDeserializer.new(byte_array,byte_array_len)
    received_command = command_deserializer.deserialize
    handler = Handler.new
    command_serializer = CommandSerializer.new
    command_serializer.serialize(handler.handle_command(received_command))
  end
end
