from javonet.core.generator.internal.SharedHandlerType import SharedHandlerType


class CommonGenerator:

    @staticmethod
    def process_method_arguments(existing_string_builder, common_command, type_array, name_array, handlers):

        for i in range(0, len(name_array)):
            handlers.SHARED_HANDLER[SharedHandlerType.ARGUMENT_NAME].generate_code(existing_string_builder,
                                                                                   common_command, name_array[i],
                                                                                   handlers)
            if i < (len(name_array) - 1):
                existing_string_builder.append(", ")

    @staticmethod
    def process_method_arguments_names(existing_string_builder, common_command, name_array, handlers):
        for i in range(0, len(name_array)):
            handlers.SHARED_HANDLER[SharedHandlerType.ARGUMENT_NAME].generate_code(existing_string_builder,
                                                                                   common_command, name_array[i],
                                                                                   handlers)
            if i < (len(name_array) - 1):
                existing_string_builder.append(", ")
