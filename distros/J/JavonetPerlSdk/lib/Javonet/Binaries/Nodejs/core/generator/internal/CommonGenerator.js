const SharedHandlerType = require("./SharedHandlerType");

class CommonGenerator {

    static process_method_arguments(existing_string_builder, common_command, type_array, name_array, handlers) {

        for (let i = 0; i < name_array.length; i++) {
            handlers.SHARED_HANDLER[SharedHandlerType.ARGUMENT_NAME].generate_code(existing_string_builder, common_command, name_array[i], handlers)
            if (i < name_array.length - 1) {
                existing_string_builder.append(", ")
            }
        }
    }

    static process_method_arguments_names(existing_string_builder, common_command, name_array, handlers) {
        for (let i = 0; i < name_array.length; i++) {
            handlers.SHARED_HANDLER[SharedHandlerType.ARGUMENT_NAME].generate_code(existing_string_builder,
                common_command, name_array[i], handlers)
            if (i < name_array.length - 1) {
                existing_string_builder.append(", ")
            }
        }
    }
}

module.exports = CommonGenerator