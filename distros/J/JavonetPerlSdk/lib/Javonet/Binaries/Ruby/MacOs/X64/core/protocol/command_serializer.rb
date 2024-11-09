require_relative 'type_serializer'
require_relative '../../utils/command'
require_relative '../../utils/runtime_name'
require_relative '../../utils/tcp_connection_data'

class CommandSerializer
  def initialize
    @buffer = []
  end

  def serialize(root_command, connection_data = nil, runtime_version = 0)
    insert_into_buffer([root_command.runtime_name, runtime_version])
    if connection_data.nil?
      insert_into_buffer([0, 0, 0, 0, 0, 0, 0])
    else
      insert_into_buffer(connection_data.serialize_connection_data)
    end
    insert_into_buffer([RuntimeName::PYTHON, root_command.command_type])
    serialize_recursively(root_command)
    @buffer
  end

  def serialize_recursively(command)
    command.payload.each do |item|
      if item.is_a?(Command)
        insert_into_buffer(TypeSerializer.serialize_command(item))
        serialize_recursively(item)
      else
        insert_into_buffer(TypeSerializer.serialize_primitive(item))
      end
    end
  end

  def insert_into_buffer(arguments)
    @buffer += arguments
  end
end