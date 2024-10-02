const AbstractGeneratorHandler = require("../../AbstractGeneratorHandler");
const CommonGenerator = require("../../../internal/CommonGenerator");
const SharedHandlerType = require("../../../internal/SharedHandlerType");
const OS = require("os");

class SharedInvokeInstanceMethodBodyHandler extends AbstractGeneratorHandler {

    generate_code(existing_string_builder, common_command, used_object, handlers) {
        handlers.SHARED_HANDLER[SharedHandlerType.RETURN_TYPE].generate_code(existing_string_builder, common_command,
            used_object.payload[1],
            handlers)
        existing_string_builder.append("this.instance.")
        existing_string_builder.append("invokeInstanceMethod")
        existing_string_builder.append("(")
        existing_string_builder.append("\"")
        existing_string_builder.append(used_object.payload[0])
        existing_string_builder.append("\"")
        existing_string_builder.append(", ")
        CommonGenerator.process_method_arguments_names(existing_string_builder, common_command,
            used_object.payload[4], handlers)
        existing_string_builder.append(").")
        existing_string_builder.append("execute().resultValue")
        existing_string_builder.append(OS.EOL)
    }
}

module.exports = SharedInvokeInstanceMethodBodyHandler