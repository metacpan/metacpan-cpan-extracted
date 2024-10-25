require_relative '../protocol/command_serializer'
require_relative '../protocol/command_deserializer'
require_relative '../handler/handler'

class Interpreter
  @@handler = Handler.new

  def execute(command, connection_type, tcp_connection_data)
    message_byte_array = CommandSerializer.new.serialize(command, connection_type, tcp_connection_data)
    if command.runtime_name == RuntimeName::RUBY && connection_type == ConnectionType::IN_MEMORY
      require_relative '../receiver/receiver'
      response_byte_array = Receiver.new.send_command(message_byte_array, message_byte_array.length)
    else
      require_relative '../transmitter/transmitter'
      response_byte_array = Transmitter.send_command(message_byte_array, message_byte_array.length)
    end

    CommandDeserializer.new(response_byte_array).deserialize
  end

  def process(byte_array, byte_array_len)
    received_command = CommandDeserializer.new(byte_array).deserialize
    CommandSerializer.new.serialize(@@handler.handle_command(received_command))
  end
end
