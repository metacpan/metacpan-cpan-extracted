require_relative 'abstract_command_handler'

class ArraySetItemHandler < AbstractCommandHandler
  def initialize
    @required_parameters_count = 3
  end

  def process(command)
    begin
      if command.payload.length < @required_parameters_count
        raise ArgumentError.new "Array set item parameters mismatch"
      end
      if command.payload[0].is_a? Array
        set_item_array(command)
      elsif command.payload[0].is_a? Hash
        set_item_hash(command)
      else
        raise ArgumentError.new "Cannot set element of %s" % [command.payload[0]]
      end
      return 0
    rescue Exception => e
      return e
    end
  end

  def set_item_array(command)
    array = command.payload[0]
    value = command.payload[2]
    indexes = if command.payload[1].is_a? Array
                command.payload[1]
              else
                [command.payload[1]]
              end
    indexes[..-2].each { |i|
      array = array[i]
    }
    array[indexes[-1]] = value
  end

  def set_item_hash(command)
    hash = command.payload[0]
    key = command.payload[1]
    value = command.payload[2]
    hash[key] = value
  end

end