require_relative 'abstract_command_handler'

class CastingHandler < AbstractCommandHandler
  def process(command)
    begin
      raise "Explicit cast is forbidden in dynamically typed languages"
    rescue Exception => e
      return e
    end
  end
end