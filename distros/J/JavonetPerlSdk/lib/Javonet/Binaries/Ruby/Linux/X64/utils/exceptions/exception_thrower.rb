require_relative './exception_type'

class ExceptionThrower

  def self.throw_exception(exception_command)
    exception_code = exception_command.payload[0]
    javonet_stack_command = exception_command.payload[1]
    exception_name = exception_command.payload[2]
    exception_message = exception_command.payload[3]

    exception_object = get_exception_object(exception_code, exception_message)

    stack_trace = get_local_stack_trace(exception_command.payload[4], exception_command.payload[5], exception_command.payload[6], exception_command.payload[7])
    exception_object.set_backtrace(stack_trace)
    return exception_object
  end

  def self.get_local_stack_trace(stack_trace_classes, stack_trace_methods, stack_trace_lines, stack_trace_files)
    stack_classes_array = stack_trace_classes.split("|")
    stack_methods_array = stack_trace_methods.split("|")
    stack_lines_array = stack_trace_lines.split("|")
    stack_files_array = stack_trace_files.split("|")

    stack_trace = ""
    stack_classes_array.each_with_index do |class_name, i|
      if (i < stack_files_array.length and stack_files_array[i] != "")
        stack_trace += "#{stack_files_array[i]}:"
      end
      if (i < stack_lines_array.length and stack_lines_array[i] != "")
        stack_trace += "#{stack_lines_array[i]} "
      end
      if (class_name != "")
        stack_trace += "in '#{class_name}#"
      end
      if (i < stack_methods_array.length and stack_methods_array[i] != "")
        stack_trace += "#{stack_methods_array[i]}'\n"
      end
    end

    return stack_trace
  end

  def self.get_exception_object(exception_code, exception_message)
    case exception_code
    when ExceptionType::EXCEPTION
      return Exception.new("Exception " + exception_message)
    when ExceptionType::IO_EXCEPTION
      return IOError.new("IOError " + exception_message)
    when ExceptionType::FILE_NOT_FOUND_EXCEPTION
      return Errno::ENOENT.new("Errno::ENOENT " + exception_message)
    when ExceptionType::RUNTIME_EXCEPTION
      return RuntimeError.new("RuntimeError " + exception_message)
    when ExceptionType::ARITHMETIC_EXCEPTION
      return ZeroDivisionError.new("ZeroDivisionError " + exception_message)
    when ExceptionType::ILLEGAL_ARGUMENT_EXCEPTION
      return ArgumentError.new("ArgumentError " + exception_message)
    when ExceptionType::INDEX_OUT_OF_BOUNDS_EXCEPTION
      return IndexError.new("IndexError " + exception_message)
    when ExceptionType::NULL_POINTER_EXCEPTION
      return TypeError.new("TypeError " + exception_message)
    else
      return Exception.new(exception_code.to_s + " " + exception_message)
    end
  end
end
