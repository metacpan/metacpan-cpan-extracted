from javonet.core.generator.handler.AbstractGeneretatorHandler import AbstractGeneratorHandler
from javonet.core.generator.internal.SharedHandlerType import SharedHandlerType
from javonet.utils.Command import Command
from javonet.utils.CommandType import CommandType
from javonet.utils.RuntimeName import RuntimeName


class GetStaticFieldGeneratorHandler(AbstractGeneratorHandler):

    def generate_command(self, analyzed_object, parent_command, handlers):
        get_static_field_command = Command(RuntimeName.python, CommandType.GetStaticField, [])
        get_static_field_command = get_static_field_command.add_arg_to_payload(
            handlers.SHARED_HANDLER[SharedHandlerType.METHOD_NAME].generate_command(analyzed_object[0],
                                                                                    get_static_field_command, handlers))
        get_static_field_command = get_static_field_command.add_arg_to_payload(
            handlers.SHARED_HANDLER[SharedHandlerType.TYPE].generate_command(analyzed_object[1],
                                                                             get_static_field_command,
                                                                             handlers))
        get_static_field_command = get_static_field_command.add_arg_to_payload(
            handlers.SHARED_HANDLER[SharedHandlerType.MODIFIER].generate_command(analyzed_object,
                                                                                 get_static_field_command,
                                                                                 handlers))
        get_static_field_command = get_static_field_command.add_arg_to_payload(
            handlers.SHARED_HANDLER[SharedHandlerType.CLASS_NAME].generate_command(parent_command.get_payload()[0],
                                                                                   get_static_field_command,
                                                                                   handlers))
        return get_static_field_command

    def generate_code(self, existing_string_builder, common_command, used_object, handlers):
        existing_string_builder.append("    ")
        handlers.SHARED_HANDLER[SharedHandlerType.MODIFIER].generate_code(existing_string_builder, common_command,
                                                                          used_object.get_payload()[2], handlers)

        handlers.SHARED_HANDLER[SharedHandlerType.METHOD_NAME].generate_code(existing_string_builder, common_command,
                                                                             used_object.get_payload()[0], handlers)
        existing_string_builder.append(" = ")
        handlers.SHARED_BODY_HANDLER[CommandType.GetStaticField].generate_code(existing_string_builder,
                                                                               common_command,
                                                                               used_object, handlers)
