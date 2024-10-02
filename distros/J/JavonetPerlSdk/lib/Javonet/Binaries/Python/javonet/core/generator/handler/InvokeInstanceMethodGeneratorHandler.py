import inspect
import typing

from javonet.core.generator.handler.AbstractGeneretatorHandler import AbstractGeneratorHandler
from javonet.core.generator.internal.CommonGenerator import CommonGenerator
from javonet.core.generator.internal.SharedHandlerType import SharedHandlerType
from javonet.utils.Command import Command
from javonet.utils.CommandType import CommandType
from javonet.utils.RuntimeName import RuntimeName


class InvokeInstanceMethodGeneratorHandler(AbstractGeneratorHandler):
    def generate_command(self, analyzed_object, parent_command, handlers):
        invoke_instance_method_command = Command(RuntimeName.python, CommandType.InvokeInstanceMethod, [])
        invoke_instance_method_command = invoke_instance_method_command.add_arg_to_payload(analyzed_object.__name__)
        invoke_instance_method_command = invoke_instance_method_command.add_arg_to_payload(
            # TODO: what to do with dynamic language with unknown type
            handlers.SHARED_HANDLER[SharedHandlerType.RETURN_TYPE].generate_command(
                typing.get_type_hints(analyzed_object),
                invoke_instance_method_command,
                handlers))
        invoke_instance_method_command = invoke_instance_method_command.add_arg_to_payload(
            handlers.SHARED_HANDLER[SharedHandlerType.MODIFIER].generate_command(analyzed_object.__name__,
                                                                                 invoke_instance_method_command,
                                                                                 handlers))
        parameter_types = []
        parameter_names = list(inspect.getfullargspec(analyzed_object)[0])
        parameters_dict = inspect.getfullargspec(analyzed_object)[6]
        for parameter_name in parameter_names:
            parameter_types.append(handlers.SHARED_HANDLER[SharedHandlerType.TYPE].generate_command(
                str(parameters_dict.get(parameter_name, "")),
                invoke_instance_method_command,
                handlers))

        invoke_instance_method_command = invoke_instance_method_command.add_arg_to_payload(parameter_types[1:])
        invoke_instance_method_command = invoke_instance_method_command.add_arg_to_payload(parameter_names[1:])
        return invoke_instance_method_command

    def generate_code(self, existing_string_builder, common_command, used_object, handlers):
        existing_string_builder.append("    def ")
        handlers.SHARED_HANDLER[SharedHandlerType.MODIFIER].generate_code(existing_string_builder, common_command,
                                                                          used_object.get_payload()[2], handlers)
        handlers.SHARED_HANDLER[SharedHandlerType.METHOD_NAME].generate_code(existing_string_builder, common_command,
                                                                             used_object.get_payload()[0], handlers)
        existing_string_builder.append("(self")
        if len(used_object.get_payload()[4]) > 0:
            existing_string_builder.append(", ")
        CommonGenerator.process_method_arguments(existing_string_builder, common_command, used_object.get_payload()[3],
                                                 used_object.get_payload()[4], handlers)
        existing_string_builder.append("):")
        existing_string_builder.append("\n")
        handlers.SHARED_HANDLER[SharedHandlerType.METHOD_BODY].generate_code(existing_string_builder, common_command,
                                                                             used_object, handlers)
