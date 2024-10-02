const AbstractGeneratorHandler = require("./AbstractGeneratorHandler");
const SharedHandlerType = require("../internal/SharedHandlerType");
const OS = require("os");

class GetInstanceFieldGeneratorHandler extends AbstractGeneratorHandler {

    generate_code(existing_string_builder, common_command, used_object, handlers) {
        existing_string_builder.append("get ")
        handlers.SHARED_HANDLER[SharedHandlerType.METHOD_NAME].generate_code(existing_string_builder, common_command, used_object.payload[0], handlers)
        existing_string_builder.append("(")
        existing_string_builder.append(")")
        existing_string_builder.append(OS.EOL)
        handlers.SHARED_HANDLER[SharedHandlerType.METHOD_BODY].generate_code(existing_string_builder, common_command, used_object, handlers)

    }
}

module.exports = GetInstanceFieldGeneratorHandler