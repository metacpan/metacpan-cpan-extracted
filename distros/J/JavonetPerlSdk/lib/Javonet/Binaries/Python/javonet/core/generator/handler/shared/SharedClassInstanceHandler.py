from javonet.core.generator.handler.AbstractGeneretatorHandler import AbstractGeneratorHandler


class SharedClassInstanceHandler(AbstractGeneratorHandler):

    def generate_command(self, analyzed_object, parent_command, handlers):
        return analyzed_object

    def generate_code(self, existing_string_builder, common_command, used_object, handlers):
        existing_string_builder.append("\n")
        existing_string_builder.append("    instance = None")
        existing_string_builder.append("\n")
