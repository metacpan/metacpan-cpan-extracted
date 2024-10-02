require_relative 'handler_dictionary'

class AbstractCommandHandler

  @required_parameters_count = 0

  def handle_command(command)
    iterate(command)
    return process(command)
  end

  def iterate(command)
    (0..command.payload.length).step(1) do |i|
      if command.payload[i].is_a? Command
        command.payload[i] = $handler_dict[command.payload[i].command_type].handle_command(command.payload[i])
      end
    end
  end

  def process(command)
    raise 'process is not implemented'
  end

end