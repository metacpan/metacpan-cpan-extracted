const AbstractGeneratorHandler = require("./AbstractGeneratorHandler");
const CommonGenerator = require("../internal/CommonGenerator");
const SharedHandlerType = require("../internal/SharedHandlerType");
const OS = require("os");

class InvokeInstanceMethodGeneratorHandler extends AbstractGeneratorHandler {

    generate_code(existing_string_builder, common_command, used_object, handlers) {
        handlers.SHARED_HANDLER[SharedHandlerType.METHOD_NAME].generate_code(existing_string_builder, common_command, used_object.payload[0], handlers)
        existing_string_builder.append("(")
        CommonGenerator.process_method_arguments(existing_string_builder, common_command, used_object.payload[3], used_object.payload[4], handlers)
        existing_string_builder.append(")")
        existing_string_builder.append(OS.EOL)
        handlers.SHARED_HANDLER[SharedHandlerType.METHOD_BODY].generate_code(existing_string_builder, common_command, used_object, handlers)
    }
}

module.exports = InvokeInstanceMethodGeneratorHandler