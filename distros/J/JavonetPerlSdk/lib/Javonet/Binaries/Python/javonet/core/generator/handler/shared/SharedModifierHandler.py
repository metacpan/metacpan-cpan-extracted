from javonet.core.generator.handler.AbstractGeneretatorHandler import AbstractGeneratorHandler


class SharedModifierHandler(AbstractGeneratorHandler):

    def generate_command(self, analyzed_object, parent_command, handlers):

        if analyzed_object[0] == "_" and analyzed_object[1] == "_":
            return "private"
        if analyzed_object[0] == "_":
            return "protected"
        else:
            return "public"

    def generate_code(self, existing_string_builder, common_command, used_object, handlers):
        if used_object == "public" or used_object == "":
            existing_string_builder.append("")
        if used_object == "protected":
            existing_string_builder.append("_")
        if used_object == "private":
            existing_string_builder.append("__")
