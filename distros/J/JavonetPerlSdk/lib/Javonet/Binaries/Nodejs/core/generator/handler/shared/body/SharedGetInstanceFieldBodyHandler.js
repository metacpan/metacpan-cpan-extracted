const AbstractGeneratorHandler = require("../../AbstractGeneratorHandler");
const SharedHandlerType = require("../../../internal/SharedHandlerType");
const OS = require("os");

class SharedGetInstanceFieldBodyHandler extends AbstractGeneratorHandler {

    generate_code(existing_string_builder, common_command, used_object, handlers) {
        handlers.SHARED_HANDLER[SharedHandlerType.RETURN_TYPE].generate_code(existing_string_builder, common_command,
            used_object.payload[1],
            handlers)
        existing_string_builder.append("this.instance.getInstanceField(\"")
        existing_string_builder.append(used_object.payload[0])
        existing_string_builder.append("\").")
        existing_string_builder.append("execute().resultValue")
        existing_string_builder.append(OS.EOL)
    }
}

module.exports = SharedGetInstanceFieldBodyHandler
