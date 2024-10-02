import os
import traceback

from javonet.core.generator.internal.PythonStringBuilder import PythonStringBuilder
from javonet.utils.ExceptionType import ExceptionType

from javonet.utils.Command import Command
from javonet.utils.CommandType import CommandType


class ExceptionSerializer:

    @staticmethod
    def serialize_exception(exception, command):
        exception_command = Command(command.runtime_name, CommandType.Exception, [])
        tb = exception.__traceback__
        trace = traceback.extract_tb(tb)
        exception_message = str(exception)
        exception_name = exception.__cause__.__class__.__name__
        stack_classes = PythonStringBuilder()
        stack_methods = PythonStringBuilder()
        stack_lines = PythonStringBuilder()
        stack_files = PythonStringBuilder()

        is_debug = False

        for frame_summary in trace:
            if "javonet" not in frame_summary.filename or is_debug:
                stack_classes.append(ExceptionSerializer.format_class_name_from_file(frame_summary.filename)).append("|")
                stack_methods.append(frame_summary.name).append("|")
                stack_lines.append(str(frame_summary.lineno)).append("|")
                stack_files.append(frame_summary.filename).append("|")

        exception_command = exception_command.add_arg_to_payload(ExceptionSerializer.get_exception_code(exception_name))
        exception_command = exception_command.add_arg_to_payload(str(command))
        exception_command = exception_command.add_arg_to_payload(exception_name)
        exception_command = exception_command.add_arg_to_payload(str(exception_message))
        exception_command = exception_command.add_arg_to_payload(stack_classes.__str__())
        exception_command = exception_command.add_arg_to_payload(stack_methods.__str__())
        exception_command = exception_command.add_arg_to_payload(stack_lines.__str__())
        exception_command = exception_command.add_arg_to_payload(stack_files.__str__())

        return exception_command

    @staticmethod
    def get_exception_code(exception_name):
        return ExceptionType.to_enum(exception_name)

    Exception = 0
    IOException = 1
    FileNotFoundException = 2
    RuntimeException = 3
    ArithmeticException = 4
    IllegalArgumentException = 5
    IndexOutOfBoundsException = 6
    NullPointerException = 7

    @staticmethod
    def format_class_name_from_file(filename):
        return os.path.splitext((os.path.split(filename)[1]))[0]
