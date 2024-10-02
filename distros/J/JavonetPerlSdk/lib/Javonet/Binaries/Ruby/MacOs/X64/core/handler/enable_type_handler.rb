require_relative 'abstract_command_handler'
require_relative '../type_cache/type_cache'

class EnableTypeHandler < AbstractCommandHandler
  def initialize
    @required_parameters_count = 1
  end

  def process(command)
    begin
      if command.payload.length < @required_parameters_count
        raise "#{self.class.name} parameters mismatch!"
      end

      type_cache = TypeCache.instance

      command.payload.each do |payload|
        if payload.is_a? String
          type_cache.cache_type(payload)
        elsif payload.is_a? Array
          payload.each do |type_to_enable|
            type_cache.cache_type(type_to_enable)
          end
        end

      end
      0
    end
  rescue Exception => e
    return e
  end
end
