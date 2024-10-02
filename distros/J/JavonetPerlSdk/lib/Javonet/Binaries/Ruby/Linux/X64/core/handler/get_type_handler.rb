require_relative 'abstract_command_handler'
require_relative '../namespace_cache/namespace_cache'
require_relative '../type_cache/type_cache'

class GetTypeHandler < AbstractCommandHandler
  def initialize
    @required_parameters_count = 1
    @namespace_cache = NamespaceCache.instance
    @type_cache = TypeCache.instance
  end

  def process(command)
    begin
      if command.payload.length < @required_parameters_count
        raise "#{self.class.name} parameters mismatch!"
      end

      type_to_return = _get_type_from_payload(command)

      if type_to_return.nil?
        raise "Type #{command.payload[0]} not found"
      end

      if (@namespace_cache.is_namespace_cache_empty? && @type_cache.is_type_cache_empty?) || # both caches are empty
        @namespace_cache.is_type_allowed(type_to_return) || # namespace is allowed
        @type_cache.is_type_allowed(type_to_return)
        # continue - type is allowed
      else
        allowed_namespaces = @namespace_cache.get_cached_namespaces.join(", ")
        allowed_types = @type_cache.get_cached_types.join(", ")
        raise "Type #{type_to_return.name} not allowed. \nAllowed namespaces: #{allowed_namespaces}\nAllowed types: #{allowed_types}"
      end

      type_to_return
    rescue Exception => e
      return e
    end
end

    private

    def _get_type_from_payload(command)
      if command.payload.length == 1
        type_name = command.payload[0].split("::")
        if type_name.length == 1
          return Object::const_get(type_name[0])
        else
          return _get_type_from_nested_payload(type_name)
        end
      else
        return _get_type_from_nested_payload(command.payload)
      end
    end

    def _get_type_from_nested_payload(payload)
      loaded_module = Object::const_get(payload[0..-2].join("::"))
      loaded_module.const_get(payload[-1])
    end
  end