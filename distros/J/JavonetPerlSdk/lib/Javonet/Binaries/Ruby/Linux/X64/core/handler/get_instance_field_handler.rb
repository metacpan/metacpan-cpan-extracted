require_relative 'abstract_command_handler'

class GetInstanceFieldHandler < AbstractCommandHandler
  def initialize
    @required_parameters_count = 2
  end

  def process(command)
    get_instance_field(command)
  end

  def get_instance_field(command)
    begin
      if command.payload.length != @required_parameters_count
        raise ArgumentError.new "Instance field parameters mismatch"
      end

      merged_value = '@' + command.payload[1]
      if command.payload[0].instance_variable_defined?(merged_value)
        response = command.payload[0].instance_variable_get(merged_value)
      else
        raise "Instance field not defined"
      end
      return response
    rescue NameError
      fields = command.payload[0].instance_variables
      message = "Field #{command.payload[1]} not found in object of class #{command.payload[0].class.name}. Available fields:\n"
      fields.each { |field_iter| message += "#{field_iter}\n" }
      raise Exception, message
    rescue Exception => e
      return e
    end
  end
end
