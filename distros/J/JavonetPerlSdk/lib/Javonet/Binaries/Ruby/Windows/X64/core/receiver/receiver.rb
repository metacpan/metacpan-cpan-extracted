require_relative '../interpreter/interpreter'
require_relative '../../utils/runtime_logger'
require_relative '../protocol/command_serializer'

class Receiver
  
  def initialize
    RuntimeLogger.print_runtime_info
  end

  def send_command(message_array, message_array_len)
    CommandSerializer.new.serialize(Interpreter.new.process(message_array))
  end
  
  def heart_beat(message_array, message_array_len)
    [49,48]
  end
end
