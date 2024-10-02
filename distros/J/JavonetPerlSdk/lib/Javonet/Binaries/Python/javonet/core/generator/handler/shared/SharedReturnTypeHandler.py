from javonet.core.generator.handler.AbstractGeneretatorHandler import AbstractGeneratorHandler
from javonet.core.generator.internal.SharedHandlerType import SharedHandlerType


class SharedReturnTypeHandler(AbstractGeneratorHandler):

    def generate_command(self, analyzed_object, parent_command, handlers):
        return handlers.SHARED_HANDLER[SharedHandlerType.TYPE].generate_command(analyzed_object, parent_command, handlers)

    def generate_code(self, existing_string_builder, common_command, used_object, handlers):
        existing_string_builder.append("return ")
        handlers.SHARED_HANDLER[SharedHandlerType.TYPE].generate_code(existing_string_builder, common_command, used_object, handlers)
        existing_string_builder.append(" ")
