require_relative './exception_type'

class ExceptionSerializer

  def self.serialize_exception(exception, command)
    exception_command = Command.new(RuntimeName::RUBY, CommandType::EXCEPTION, [])

    stack_trace = exception.backtrace
    exception_message = exception.message
    exception_name = exception.class
    stack_classes = ""
    stack_methods = ""
    stack_lines = ""
    stack_files = ""
    stack_trace.each_with_index do |value, index|
      stack_file, stack_class, stack_line, stack_method = parse_stack_frame(value)
      unless stack_file.include?("javonet-ruby-sdk") or stack_file.include?("Binaries/Ruby")
        append_to_string(stack_classes, stack_class)
        append_to_string(stack_methods, stack_method)
        append_to_string(stack_lines, stack_line)
        append_to_string(stack_files, stack_file)
        if index != stack_trace.length() - 1
          append_to_string(stack_classes, "|")
          append_to_string(stack_methods, "|")
          append_to_string(stack_lines, "|")
          append_to_string(stack_files, "|")
        end
      end
    end

    exception_command = exception_command.add_arg_to_payload(get_exception_code(exception_name.to_s))
    exception_command = exception_command.add_arg_to_payload(command.to_string)
    exception_command = exception_command.add_arg_to_payload(exception_name.to_s)
    exception_command = exception_command.add_arg_to_payload(exception_message)
    exception_command = exception_command.add_arg_to_payload(stack_classes)
    exception_command = exception_command.add_arg_to_payload(stack_methods)
    exception_command = exception_command.add_arg_to_payload(stack_lines)
    exception_command = exception_command.add_arg_to_payload(stack_files)

    return exception_command
  end

  def self.append_to_string(string, value)
    if value.nil?
      string << "undefined"
    else
      string << value
    end
  end

  def self.parse_stack_frame(stack_frame)
    # Extract the file path, line number, and method name using regular expressions
    match = /(.+):(\d+):in `(.+)'/.match(stack_frame)

    # Extract the name of the file without the full path
    file_name = File.basename(match[1])

    # Extract the class name and method name
    method_name = match[3]
    file_name = File.basename(match[1], ".rb")
    class_name = file_name.split('_').map(&:capitalize).join('')
    if method_name =~ /(.+)#(.+)/
      class_name = $1.split('::')[-1]
      method_name = $2
    end

    # Return the four variables as an array
    [match[1], class_name, match[2], method_name]
  end

  def self.get_exception_code(exception_name)
    case exception_name
    when "Exception"
      return ExceptionType::EXCEPTION
    when "IOError"
      return ExceptionType::IO_EXCEPTION
    when "Errno::ENOENT"
      return ExceptionType::FILE_NOT_FOUND_EXCEPTION
    when "RuntimeError"
      return ExceptionType::RUNTIME_EXCEPTION
    when "ZeroDivisionError"
      return ExceptionType::ARITHMETIC_EXCEPTION
    when "ArgumentError"
      return ExceptionType::ILLEGAL_ARGUMENT_EXCEPTION
    when "IndexError"
      return ExceptionType::INDEX_OUT_OF_BOUNDS_EXCEPTION
    when "TypeError"
      return ExceptionType::NULL_POINTER_EXCEPTION
    else
      return exception_name
    end
  end
end
