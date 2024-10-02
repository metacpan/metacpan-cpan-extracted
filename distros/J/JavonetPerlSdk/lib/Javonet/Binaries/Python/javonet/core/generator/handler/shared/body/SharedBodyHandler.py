from javonet.core.generator.handler.AbstractGeneretatorHandler import AbstractGeneratorHandler


class SharedBodyHandler(AbstractGeneratorHandler):
    def generate_command(self, analyzed_object, parent_command, handlers):
        return analyzed_object

    def generate_code(self, existing_string_builder, common_command, used_object, handlers):
        handlers.SHARED_BODY_HANDLER[used_object.command_type].generate_code(existing_string_builder, common_command,
                                                                             used_object, handlers)
