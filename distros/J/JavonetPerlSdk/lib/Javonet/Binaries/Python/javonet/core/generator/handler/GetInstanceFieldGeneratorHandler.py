from javonet.core.generator.handler.AbstractGeneretatorHandler import AbstractGeneratorHandler
from javonet.core.generator.internal.SharedHandlerType import SharedHandlerType
from javonet.utils.Command import Command
from javonet.utils.CommandType import CommandType
from javonet.utils.RuntimeName import RuntimeName


class GetInstanceFieldGeneratorHandler(AbstractGeneratorHandler):
    def generate_command(self, analyzed_object, parent_command, handlers):
        get_instance_field_command = Command(RuntimeName.python, CommandType.GetInstanceField, [])
        get_instance_field_command = get_instance_field_command.add_arg_to_payload(
            handlers.SHARED_HANDLER[SharedHandlerType.METHOD_NAME].generate_command(analyzed_object.__name__,
                                                                                    get_instance_field_command,
                                                                                    handlers))
        get_instance_field_command = get_instance_field_command.add_arg_to_payload(
            handlers.SHARED_HANDLER[SharedHandlerType.TYPE].generate_command(type(analyzed_object),
                                                                             get_instance_field_command,
                                                                             handlers))
        get_instance_field_command = get_instance_field_command.add_arg_to_payload(
            handlers.SHARED_HANDLER[SharedHandlerType.MODIFIER].generate_command(analyzed_object.__name__,
                                                                                 get_instance_field_command, handlers))
        return get_instance_field_command

    def generate_code(self, existing_string_builder, common_command, used_object, handlers):
        existing_string_builder.append("    ")
        handlers.SHARED_HANDLER[SharedHandlerType.MODIFIER].generate_code(existing_string_builder, common_command,
                                                                          used_object.get_payload()[2], handlers)
        handlers.SHARED_HANDLER[SharedHandlerType.METHOD_NAME].generate_code(existing_string_builder, common_command,
                                                                             used_object.get_payload()[0], handlers)
        existing_string_builder.append(" ")
        existing_string_builder.append("=")
        existing_string_builder.append(" ")
        handlers.SHARED_BODY_HANDLER[CommandType.GetInstanceField].generate_code(existing_string_builder,
                                                                                 common_command,
                                                                                 used_object,
                                                                                 handlers)
