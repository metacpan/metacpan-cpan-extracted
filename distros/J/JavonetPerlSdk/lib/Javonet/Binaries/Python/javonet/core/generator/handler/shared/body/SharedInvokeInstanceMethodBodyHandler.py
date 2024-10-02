from javonet.core.generator.handler.AbstractGeneretatorHandler import AbstractGeneratorHandler
from javonet.core.generator.internal.CommonGenerator import CommonGenerator
from javonet.core.generator.internal.SharedHandlerType import SharedHandlerType


class SharedInvokeInstanceMethodBodyHandler(AbstractGeneratorHandler):
    def generate_command(self, analyzed_object, parent_command, handlers):
        return analyzed_object

    def generate_code(self, existing_string_builder, common_command, used_object, handlers):
        if isinstance(used_object.get_payload()[1], str):
            existing_string_builder.append("        ")
            existing_string_builder.append("result = ")
            existing_string_builder.append("self.instance.")
            existing_string_builder.append("invoke_instance_method(\"")
            existing_string_builder.append(used_object.get_payload()[0])
            existing_string_builder.append("\", ")
            CommonGenerator.process_method_arguments_names(existing_string_builder, common_command,
                                                           used_object.get_payload()[5], handlers)
            existing_string_builder.append(").")
            existing_string_builder.append("execute()")
            existing_string_builder.append("\n")
            existing_string_builder.append("        import ")
            existing_string_builder.append(used_object.get_payload()[1])
            existing_string_builder.append("\n")
            existing_string_builder.append("        classInstance = ")
            existing_string_builder.append(used_object.get_payload()[1])
            existing_string_builder.append("(result)")
            existing_string_builder.append("\n")
            existing_string_builder.append("        return classInstance")
        else:
            existing_string_builder.append("        ")
            handlers.SHARED_HANDLER[SharedHandlerType.RETURN_TYPE].generate_code(existing_string_builder, common_command,
                                                                                 used_object.get_payload()[1],
                                                                                 handlers)
            existing_string_builder.append("(self.instance.")
            existing_string_builder.append("invoke_instance_method")
            existing_string_builder.append("(")
            existing_string_builder.append("\"")
            existing_string_builder.append(used_object.get_payload()[0])
            existing_string_builder.append("\"")
            existing_string_builder.append(", ")
            CommonGenerator.process_method_arguments_names(existing_string_builder, common_command,
                                                           used_object.get_payload()[4], handlers)
            existing_string_builder.append(").")
            existing_string_builder.append("execute().get_value())")
            existing_string_builder.append("\n")
