from javonet.core.generator.handler.AbstractGeneretatorHandler import AbstractGeneratorHandler
from javonet.utils.Type import Type


class SharedTypeHandler(AbstractGeneratorHandler):

    def generate_command(self, analyzed_object, parent_command, handlers):
        if analyzed_object == "":
            return Type.Command.value
        if analyzed_object == "str":
            return Type.JavonetString.value
        if analyzed_object == "int":
            return Type.JavonetInteger.value
        if analyzed_object == "bool":
            return Type.JavonetBoolean.value
        if analyzed_object == "float":
            return Type.JavonetFloat.value
        if analyzed_object == "bytes":
            return Type.JavonetByte.value
        if analyzed_object == "double":
            return Type.JavonetDouble.value
        if analyzed_object == "char":
            return Type.JavonetChar.value
        else:
            self.complex_command_type_generator(handlers, analyzed_object)
            return str(analyzed_object)

    def generate_code(self, existing_string_builder, common_command, used_object, handlers):
        if used_object is Type.Command:
            pass
        if used_object is Type.JavonetString.value:
            existing_string_builder.append("str")
        if used_object is Type.JavonetInteger.value:
            existing_string_builder.append("int")
        if used_object is Type.JavonetBoolean.value:
            existing_string_builder.append("bool")
        if used_object is Type.JavonetFloat.value:
            existing_string_builder.append("float")
        if used_object is Type.JavonetByte.value:
            existing_string_builder.append("bytes")
        if used_object is Type.JavonetChar.value:
            existing_string_builder.append("int")
        if used_object is Type.JavonetLongLong.value:
            existing_string_builder.append("double")
        if used_object is Type.JavonetDouble.value:
            existing_string_builder.append("int")
        if used_object is Type.JavonetUnsignedLongLong.value:
            existing_string_builder.append("int")
        if used_object is Type.JavonetUnsignedInteger.value:
            existing_string_builder.append("int")
        else:
            existing_string_builder.append("")
        # else:
        #     raise Exception("SharedHandlerTypeException: This type is not supported: " + str(used_object))

    def complex_command_type_generator(self, handlers, analyzed_object):
        return ""
