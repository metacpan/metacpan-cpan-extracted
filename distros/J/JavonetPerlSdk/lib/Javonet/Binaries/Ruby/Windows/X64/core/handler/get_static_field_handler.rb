require_relative 'abstract_command_handler'

class GetStaticFieldHandler < AbstractCommandHandler
  def initialize
    @required_parameters_count = 2
  end

  def process(command)
    get_static_field(command)
  end

  def get_static_field(command)
    begin
      if command.payload.length != @required_parameters_count
        raise ArgumentError.new "Static field parameters mismatch"
      end

      merged_value = '@@' + command.payload[1]
      if command.payload[0].class_variable_defined?(merged_value)
        response = command.payload[0].class_variable_get(merged_value)
      else
        response = command.payload[0].const_get(command.payload[1])
      end
      return response
    rescue NameError
      fields = command.payload[0].class_variables
      message = "Field #{command.payload[1]} not found in class #{command.payload[0].name}. Available fields:\n"
      fields.each { |field_iter| message += "#{field_iter}\n" }
      raise Exception, message
    rescue Exception => e
      return e
    end
  end
end
