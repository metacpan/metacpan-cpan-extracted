require_relative 'abstract_command_handler'

class ArrayGetSizeHandler < AbstractCommandHandler
  def initialize
    @required_parameters_count = 1
  end

  def process(command)
    begin
      if command.payload.length < @required_parameters_count
        raise ArgumentError.new "Array get size parameters mismatch"
      end

      if command.payload[0].is_a? Array
        return get_size_array(command)
      else
        return get_size(command)
      end
    rescue Exception => e
      return e
    end
  end

  def get_size_array(command)
    array = command.payload[0]
    size = 1
    while array.is_a? Array
      size = size * array.length
      array = array[0]
    end
    size
  end

  def get_size(command)
    command.payload[0].length
  end
end