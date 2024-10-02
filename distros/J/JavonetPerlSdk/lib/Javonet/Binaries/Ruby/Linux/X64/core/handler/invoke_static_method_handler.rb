require_relative 'abstract_command_handler'

class InvokeStaticMethodHandler < AbstractCommandHandler
  def initialize
    @required_parameters_count = 2
  end

  def process(command)
    invoke_static_method(command)
  end

  def invoke_static_method(command)
    begin
      if command.payload.length < @required_parameters_count
        raise ArgumentError.new "Static method parameters mismatch"
      end
  
      method_name = command.payload[1]
      begin
        if command.payload.length > @required_parameters_count
          args = command.payload[2..]
          result = command.payload[0].send(method_name, *args)
        else
          result = command.payload[0].send(method_name)
        end
        return result
      rescue NoMethodError
        methods = command.payload[0].methods
        message = "Method #{method_name} not found in class #{command.payload[0].name}. Available methods:\n"
        methods.each { |method_iter| message += "#{method_iter}\n" }
        raise Exception, message
      end
    rescue Exception => e
      return e
    end
  end
end
