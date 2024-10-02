from javonet.core.generator.handler.AbstractGeneretatorHandler import AbstractGeneratorHandler
from javonet.core.generator.internal.SharedHandlerType import SharedHandlerType


class SharedGetInstanceFieldBodyHandler(AbstractGeneratorHandler):
    def generate_command(self, analyzed_object, parent_command, handlers):
        return analyzed_object

    def generate_code(self, existing_string_builder, common_command, used_object, handlers):
        handlers.SHARED_HANDLER[SharedHandlerType.TYPE].generate_code(existing_string_builder, common_command,
                                                                      used_object.get_payload()[1], handlers)
        existing_string_builder.append("(instance.get_instance_field(\"")
        existing_string_builder.append(used_object.get_payload()[0])
        existing_string_builder.append("\").")
        existing_string_builder.append("execute().get_value())")
        existing_string_builder.append("\n")
