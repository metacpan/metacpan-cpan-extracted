require_relative 'abstract_command_handler'

class LoadLibraryHandler < AbstractCommandHandler
  def initialize
    @required_parameters_count = 1
  end

  def process(command)
    begin
      if command.payload.length < @required_parameters_count
        raise ArgumentError.new "Load library parameters mismatch"
      end
      if command.payload.length > @required_parameters_count
        assembly_name = command.payload[1]
      else
        assembly_name = command.payload[0]
      end
      #noinspection RubyResolve
      require(assembly_name)
      return 0
    rescue Exception => e
      return e
    end
  end
end