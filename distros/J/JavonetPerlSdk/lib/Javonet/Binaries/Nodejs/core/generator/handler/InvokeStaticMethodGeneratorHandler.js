const AbstractGeneratorHandler = require("./AbstractGeneratorHandler");
const SharedHandlerType = require("../internal/SharedHandlerType");
const CommonGenerator = require("../internal/CommonGenerator");
const OS = require("os");

class InvokeStaticMethodGeneratorHandler extends AbstractGeneratorHandler {

    generate_code(existing_string_builder, common_command, used_object, handlers) {
        existing_string_builder.append(OS.EOL)
        existing_string_builder.append("static ")
        handlers.SHARED_HANDLER[SharedHandlerType.METHOD_NAME].generate_code(existing_string_builder, common_command, used_object.payload[0], handlers)
        existing_string_builder.append("(")
        CommonGenerator.process_method_arguments(existing_string_builder, common_command, used_object.payload[4], used_object.payload[5], handlers)
        existing_string_builder.append(")")
        existing_string_builder.append(OS.EOL)
        handlers.SHARED_HANDLER[SharedHandlerType.METHOD_BODY].generate_code(existing_string_builder, common_command, used_object, handlers)
    }
}

module.exports = InvokeStaticMethodGeneratorHandler