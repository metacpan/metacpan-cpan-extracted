require_relative 'abstract_command_handler'

class ValueHandler < AbstractCommandHandler
  def process(command)
    command.payload[0]
  end
end