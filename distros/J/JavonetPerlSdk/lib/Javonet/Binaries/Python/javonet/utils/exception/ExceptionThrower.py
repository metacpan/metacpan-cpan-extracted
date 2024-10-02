import re

from javonet.utils.exception.JavonetException import JavonetException
from javonet.utils.Command import Command
from javonet.utils.ExceptionType import ExceptionType


class ExceptionThrower:

    @staticmethod
    def throw_exception(command_exception: Command):
        stack_classes, stack_methods, stack_lines, stack_files = "", "", "", ""
        exception_message = "Python Exception with empty message"
        exception_name = "Python exception"
        javonet_stack_command = ""
        traceback_str = ""

        exception_payload_len = len(command_exception.payload)
        if exception_payload_len >=8:
            stack_classes, stack_methods, stack_lines, stack_files = ExceptionThrower.get_local_stack_trace(
                command_exception.get_payload()[4],
                command_exception.get_payload()[5],
                command_exception.get_payload()[6],
                command_exception.get_payload()[7])

        if exception_payload_len >= 4:
            exception_message = command_exception.get_payload()[3]

        if exception_payload_len >= 3:
            exception_name = command_exception.get_payload()[2]

        if exception_payload_len >= 2:
            javonet_stack_command = command_exception.get_payload()[1]

        if exception_payload_len >= 1:
            original_exception = ExceptionType.to_exception(command_exception.get_payload()[0])


        for i in range(len(stack_classes)):
            if i < len(stack_files) and stack_files[i]:
                traceback_str += "File \"{}\"".format(stack_files[i])
            if i < len(stack_lines) and stack_lines[i]:
                traceback_str += ", line {}".format(stack_lines[i])
            if i < len(stack_methods) and stack_methods[i]:
                traceback_str += ", in {}".format(stack_methods[i])
            traceback_str += "\n"
            if i < len(stack_classes) and stack_classes[i]:
                traceback_str += "    {}\n".format(stack_classes[i])

        return ExceptionThrower.raise_exception(original_exception, exception_message, traceback_str)

    @staticmethod
    def raise_exception(original_exception, exception_message, traceback_str):
        return JavonetException(str(original_exception), exception_message, traceback_str)

    @staticmethod
    def get_local_stack_trace(stack_trace_classes, stack_trace_methods, stack_trace_lines, stack_trace_files):
        try:
            stack_classes = re.split("\\|", stack_trace_classes)
        except Exception:
            stack_classes = ""

        try:
            stack_methods = re.split("\\|", stack_trace_methods)
        except Exception:
            stack_methods = ""

        try:
            stack_lines = re.split("\\|", stack_trace_lines)
        except Exception:
            stack_lines = ""

        try:
            stack_files = re.split("\\|", stack_trace_files)
        except Exception:
            stack_files = ""
        return [stack_classes, stack_methods, stack_lines, stack_files]
