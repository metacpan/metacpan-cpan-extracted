$handler_dict = Hash.new

class HandlerDictionary

  def self.add_handler_to_dict(command_type, handler)
    $handler_dict[command_type] = handler
  end
end