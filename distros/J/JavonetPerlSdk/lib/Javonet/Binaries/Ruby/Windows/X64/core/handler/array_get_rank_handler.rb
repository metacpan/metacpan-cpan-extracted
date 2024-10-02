require_relative 'abstract_command_handler'

class ArrayGetRankHandler < AbstractCommandHandler
  def initialize
    @required_parameters_count = 1
  end
  def process(command)
    begin
      if command.payload.length < @required_parameters_count
        raise ArgumentError.new "Array get rank parameters mismatch"
      end
      array = command.payload[0]
      rank = 0
      while array.is_a? Array
        rank = rank + 1
        array = array[0]
      end
      return rank
    rescue Exception => e
      return e
    end
  end
end