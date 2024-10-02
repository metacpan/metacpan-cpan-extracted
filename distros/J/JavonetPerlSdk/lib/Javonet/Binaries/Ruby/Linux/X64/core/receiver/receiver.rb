require_relative '../interpreter/interpreter'

class Receiver
  
  def initialize
    @@interpreter = Interpreter.new
  end

  def send_command(message_array, message_array_len)
    @@interpreter.process(message_array, message_array_len)
  end
  
  def heart_beat(message_array, message_array_len)
    [49,48]
  end
end
