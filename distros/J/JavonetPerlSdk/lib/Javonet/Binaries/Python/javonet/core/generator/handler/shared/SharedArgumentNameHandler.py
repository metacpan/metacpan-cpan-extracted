from javonet.core.generator.handler.AbstractGeneretatorHandler import AbstractGeneratorHandler
from javonet.core.generator.internal.SharedHandlerType import SharedHandlerType


class SharedArgumentNameHandler(AbstractGeneratorHandler):
    def generate_command(self, analyzed_object, parent_command, handlers):
        handlers.SHARED_HANDLER[SharedHandlerType.METHOD_NAME].generate_command(analyzed_object, parent_command,
                                                                                handlers)

    def generate_code(self, existing_string_builder, common_command, used_object, handlers):
        handlers.SHARED_HANDLER[SharedHandlerType.METHOD_NAME].generate_code(existing_string_builder, common_command,
                                                                             used_object, handlers)
