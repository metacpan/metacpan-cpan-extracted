require_relative 'abstract_command_handler'

class ArrayHandler < AbstractCommandHandler
  def process(command)
    begin
      processedArray = command.payload
      return processedArray
    rescue Exception => e
      return e
    end
  end
end