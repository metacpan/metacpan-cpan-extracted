require_relative 'abstract_command_handler'
require_relative '../namespace_cache/namespace_cache'

class EnableNamespaceHandler < AbstractCommandHandler
  def initialize
    @required_parameters_count = 1
  end

  def process(command)
    begin
      if command.payload.length < @required_parameters_count
        raise ArgumentError.new "#{self.class.name} parameters mismatch"
      end
      namespace_cache = NamespaceCache.instance

      command.payload.each do |payload|
        if payload.is_a? String
          namespace_cache.cache_namespace(payload)
        elsif payload.is_a? Array
          payload.each do |type_to_enable|
            namespace_cache.cache_namespace(type_to_enable)
            cache_namespace
          end
        end
      end
      0
    rescue Exception => e
      return e
    end
  end
end