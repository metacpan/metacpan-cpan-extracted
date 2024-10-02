require_relative 'abstract_command_handler'

class ArrayGetItemHandler < AbstractCommandHandler
  def initialize
    @required_parameters_count = 2
  end

  def process(command)
    begin
      if command.payload.length < @required_parameters_count
        raise ArgumentError.new "Array get item parameters mismatch"
      end

      if command.payload[0].is_a? Array
        return get_item_array(command)
      elsif command.payload[0].is_a? Hash
        return get_item_hash(command)
      else
        raise ArgumentError.new "Cannot get element from %s" % [command.payload[0]]
      end
    rescue Exception => e
      e
    end
  end

  def get_item_array(command)
    array = command.payload[0]
    indexes = if command.payload[1].is_a? Array
                command.payload[1]
              else
                command.payload[1..]
              end

    if array.is_a? Array
      indexes.each { |i|
        array = array[i]
      }
      array
    end
  end

  def get_item_hash(command)
    hash = command.payload[0]
    key = command.payload[1]
    hash[key]
  end
end