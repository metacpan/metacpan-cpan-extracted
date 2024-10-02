require_relative 'runtime_name'
require_relative 'runtime_name_handler'
require_relative 'command_type'

class Command
  def initialize(runtime_name, command_type, payload)
    @runtime_name = runtime_name
    @command_type = command_type
    @payload = payload
  end

  def runtime_name
    @runtime_name
  end

  def command_type
    @command_type
  end

  def payload
    @payload
  end


  def self.create_response(response, runtime_name)
    return Command.new(runtime_name, CommandType::VALUE, [response])
  end

  def self.create_reference(guid, runtime_name)
    return Command.new(runtime_name, CommandType::REFERENCE, [guid])
  end

  def self.create_array_response(array, runtime_name)
    return Command.new(runtime_name, CommandType::ARRAY, array)
  end

  def drop_first_payload_argument
    payload_args = []
    payload_args = payload_args + @payload
    if payload_args.length != 0
      payload_args.delete_at(0)
    end
    return Command.new(@runtime_name, @command_type, payload_args)
  end

  def add_arg_to_payload(argument)
    merged_payload = payload + [argument]
    return Command.new(@runtime_name, @command_type, merged_payload)
  end

  def prepend_arg_to_payload(current_command)
    if current_command.nil?
      return Command.new(@runtime_name, @command_type, @payload)
    else
      merged_payload = [current_command] + payload
      return Command.new(@runtime_name, @command_type, merged_payload)
    end
  end

  def to_string
    'Runtime Library: ' + RuntimeNameHandler.get_name(@runtime_name) + ' ' + 'Ruby command type: ' + CommandType.get_name(@command_type).to_s + ' ' + 'with parameters: ' + @payload.to_s
  end

  def eql?(other)
    @is_equal = false
    if self == other
      @is_equal = true
    end
    if other == nil or self.class != other.class
      @is_equal = false
    end
    if self.command_type == other.command_type and self.runtime_name == other.runtime_name
      @is_equal = true
    end
    if payload.length == other.payload.length
      i = 0
      array_item_equal = false
      payload.each { |payload_item|
        if payload_item.eql? other.payload[i]
          array_item_equal = true
        else
          array_item_equal = false
        end
        i += 1
      }
      @is_equal = array_item_equal
    else
      @is_equal = false
    end
    return @is_equal
  end

end