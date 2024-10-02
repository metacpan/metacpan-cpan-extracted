import inspect

from javonet.core.generator.handler.AbstractGeneretatorHandler import AbstractGeneratorHandler
from javonet.core.generator.internal.CommonGenerator import CommonGenerator
from javonet.core.generator.internal.SharedHandlerType import SharedHandlerType
from javonet.utils.Command import Command
from javonet.utils.CommandType import CommandType
from javonet.utils.RuntimeName import RuntimeName


class CreateInstanceGeneratorHandler(AbstractGeneratorHandler):
    def generate_command(self, analyzed_object, parent_command, handlers):
        create_instance_command = Command(RuntimeName.python, CommandType.CreateClassInstance, [])
        create_instance_command = create_instance_command.add_arg_to_payload(
            handlers.SHARED_HANDLER[SharedHandlerType.CLASS_NAME].generate_command(parent_command.get_payload()[0],
                                                                                   create_instance_command, handlers))
        create_instance_command = create_instance_command.add_arg_to_payload(
            handlers.SHARED_HANDLER[SharedHandlerType.MODIFIER].generate_command(analyzed_object.__name__,
                                                                                 create_instance_command, handlers))
        parameter_types = []
        parameter_names = list(inspect.getfullargspec(analyzed_object)[0])
        parameters_dict = inspect.getfullargspec(analyzed_object)[6]
        for parameter_name in parameter_names:
            parameter_types.append(handlers.SHARED_HANDLER[SharedHandlerType.TYPE].generate_command(
                str(parameters_dict.get(parameter_name, "")),
                create_instance_command,
                handlers))

        create_instance_command = create_instance_command.add_arg_to_payload(parameter_types[1:])
        create_instance_command = create_instance_command.add_arg_to_payload(parameter_names[1:])
        return create_instance_command

    def generate_code(self, existing_string_builder, common_command, used_object, handlers):

        existing_string_builder.append("    def __init__(self")
        if len(used_object.get_payload()[3]) > 0:
            existing_string_builder.append(", ")
        CommonGenerator.process_method_arguments(existing_string_builder, common_command, used_object.get_payload()[2],
                                                 used_object.get_payload()[3], handlers)
        existing_string_builder.append("):")
        handlers.SHARED_HANDLER[SharedHandlerType.METHOD_BODY].generate_code(existing_string_builder, common_command,
                                                                             used_object, handlers)

        existing_string_builder.append("\n")
