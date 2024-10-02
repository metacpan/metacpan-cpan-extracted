require_relative '../reference_cache/references_cache'
require_relative 'abstract_command_handler'

class ResolveInstanceHandler < AbstractCommandHandler
  def initialize
    @required_parameters_count = 1
  end

  def process(command)
    return resolve_reference(command)
  end

  def resolve_reference(command)
    if command.payload.length != @required_parameters_count
      raise ArgumentError.new "Resolve Instance parameters mismatch"
    end
    begin
      references_cache = ReferencesCache.instance
      return references_cache.resolve_reference(command.payload[0])
    rescue Exception => ex
      return ex
    end
  end
end