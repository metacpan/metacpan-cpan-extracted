require_relative 'abstract_command_handler'

class InvokeInstanceMethodHandler < AbstractCommandHandler
  def initialize
    @required_parameters_count = 2
  end

  def process(command)
    return invoke_instance_method(command)
  end

  def invoke_instance_method(command)
    begin
      if command.payload.length < @required_parameters_count
        raise ArgumentError.new "InvokeInstanceMethod parameters mismatch"
      end
      if command.payload.length > 2
        arguments = command.payload[2..]
        return command.payload[0].send(command.payload[1], *arguments)
      else
        return command.payload[0].send(command.payload[1])
      end
    rescue NoMethodError
      methods = command.payload[0].methods
      message = "Method #{command.payload[1]} not found in object of class #{command.payload[0].class.name}. Available methods:\n"
      methods.each { |method_iter| message += "#{method_iter}\n" }
      raise Exception, message
    rescue Exception => e
      return e
    end
  end
end