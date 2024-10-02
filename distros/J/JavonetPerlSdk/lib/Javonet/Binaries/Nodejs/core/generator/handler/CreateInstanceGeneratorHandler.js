const AbstractGeneratorHandler = require("./AbstractGeneratorHandler");
const SharedHandlerType = require("../internal/SharedHandlerType");
const CommonGenerator = require("../internal/CommonGenerator");
const OS = require("os");

class CreateInstanceGeneratorHandler extends AbstractGeneratorHandler {

    generate_code(existing_string_builder, common_command, used_object, handlers) {
        existing_string_builder.append("constructor(")
        CommonGenerator.process_method_arguments(existing_string_builder, common_command, used_object.payload[2], used_object.payload[3], handlers)
        existing_string_builder.append(")")
        handlers.SHARED_HANDLER[SharedHandlerType.METHOD_BODY].generate_code(existing_string_builder, common_command, used_object, handlers)
        existing_string_builder.append(OS.EOL)
    }
}

module.exports = CreateInstanceGeneratorHandler