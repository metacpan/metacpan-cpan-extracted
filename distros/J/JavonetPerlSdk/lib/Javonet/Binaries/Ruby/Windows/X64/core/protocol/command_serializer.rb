require_relative 'type_serializer'
require_relative '../../utils/connection_type'
require_relative '../../utils/runtime_name'
require_relative '../../utils/tcp_connection_data'

class CommandSerializer

  def initialize
    @byte_buffer = []
  end

  def serialize(root_command, connection_type = ConnectionType::IN_MEMORY, tcp_connection_data = nil, runtime_version = 0)
    queue = []
    queue.unshift(root_command)
    self.insert_into_buffer([root_command.runtime_name, runtime_version])
    self.insert_into_buffer([connection_type])
    self.insert_into_buffer(self.serialize_tcp(tcp_connection_data))
    self.insert_into_buffer([RuntimeName::RUBY, root_command.command_type])
    self.serialize_recursively(queue)
  end

  def serialize_tcp(tcp_connection_data)
    if tcp_connection_data.nil?
      return [0, 0, 0, 0, 0, 0]
    end
    tcp_connection_data.get_address_bytes + tcp_connection_data.get_port_bytes
  end

  def serialize_primitive(payload_item)
    if payload_item.nil?
      return TypeSerializer.serialize_nil
    elsif [true, false].include? payload_item
      return TypeSerializer.serialize_bool(payload_item)
    elsif payload_item.is_a? Integer
      if (-2 ** 31..2 ** 31).include?(payload_item)
        return TypeSerializer.serialize_int(payload_item)
      elsif (-2 ** 63..2 ** 63).include?(payload_item)
        return TypeSerializer.serialize_longlong(payload_item)
      else
        return TypeSerializer.serialize_ullong(payload_item)
      end
    elsif payload_item.is_a? String
      return TypeSerializer.serialize_string(payload_item)
    elsif payload_item.is_a? Float
      return TypeSerializer.serialize_double(payload_item)
    elsif payload_item.is_a?
    else
      raise Exception.new("Payload not supported in command serializer")
    end
  end

  def insert_into_buffer(arguments)
    @byte_buffer = @byte_buffer + arguments
  end

  def serialize_recursively(queue)
    if queue.length == 0
      return @byte_buffer
    end
    command = queue.shift
    queue.unshift(command.drop_first_payload_argument)
    if command.payload.length > 0
      if command.payload[0].is_a? Command
        inner_command = command.payload[0]
        self.insert_into_buffer(TypeSerializer.serialize_command(inner_command))
        queue.unshift(inner_command)
      else
        result = self.serialize_primitive(command.payload[0])
        self.insert_into_buffer(result)
        return self.serialize_recursively(queue)
      end
    else
      queue.shift
    end
    self.serialize_recursively(queue)
  end

end