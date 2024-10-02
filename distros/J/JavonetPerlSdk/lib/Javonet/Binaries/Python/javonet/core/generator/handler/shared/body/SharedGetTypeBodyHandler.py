from javonet.core.generator.handler.AbstractGeneretatorHandler import AbstractGeneratorHandler


class SharedGetTypeBodyHandler(AbstractGeneratorHandler):
    def generate_command(self, analyzed_object, parent_command, handlers):
        return analyzed_object

    def generate_code(self, existing_string_builder, common_command, used_object, handlers):
        existing_string_builder.append("return Javonet.inMemory().")
        existing_string_builder.append(str(common_command.runtime_name))
        existing_string_builder.append("().")
        existing_string_builder.append("get_type(\"")
        existing_string_builder.append(used_object.get_payload()[0])
        existing_string_builder.append("\").")
        existing_string_builder.append("execute())")
        existing_string_builder.append("\n")
