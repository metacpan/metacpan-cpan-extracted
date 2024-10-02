from javonet.core.generator.handler.AbstractGeneretatorHandler import AbstractGeneratorHandler
from javonet.core.generator.internal.CommonGenerator import CommonGenerator


class SharedCreateInstanceBodyHandler(AbstractGeneratorHandler):
    def generate_command(self, analyzed_object, parent_command, handlers):
        return analyzed_object

    def generate_code(self, existing_string_builder, common_command, used_object, handlers):
        existing_string_builder.append("\n")
        existing_string_builder.append("        self.instance = Javonet.inMemory().")
        existing_string_builder.append(str(common_command.runtime_name.name))
        existing_string_builder.append("().")
        existing_string_builder.append("get_type(\"")
        existing_string_builder.append(used_object.get_payload()[0])
        existing_string_builder.append("\").")
        existing_string_builder.append("create_instance(")
        CommonGenerator.process_method_arguments_names(existing_string_builder, common_command,
                                                       used_object.get_payload()[3], handlers)
        existing_string_builder.append(")")
        existing_string_builder.append("\n")
