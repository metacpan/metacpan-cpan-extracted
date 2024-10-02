require_relative 'abstract_command_handler'
require_relative '../reference_cache/references_cache'

class DestructReferenceHandler < AbstractCommandHandler
  def initialize
    @required_parameters_count = 1
  end

  def process(command)
    begin
      if command.payload.length == @required_parameters_count
        reference_cache = ReferencesCache.instance
        return reference_cache.delete_reference(command.payload[0])
      else
        raise ArgumentError.new "Destruct Reference Handler parameters mismatch"
      end
    rescue Exception => e
      return e
    end
  end
end