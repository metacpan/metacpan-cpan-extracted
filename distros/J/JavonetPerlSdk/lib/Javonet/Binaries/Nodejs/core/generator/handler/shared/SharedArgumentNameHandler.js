const SharedHandlerType = require("../../internal/SharedHandlerType");
const AbstractGeneratorHandler = require("../AbstractGeneratorHandler");

class SharedArgumentNameHandler extends AbstractGeneratorHandler {

    generate_code(existing_string_builder, common_command, used_object, handlers) {
        handlers.SHARED_HANDLER[SharedHandlerType.METHOD_NAME].generate_code(existing_string_builder, common_command, used_object, handlers)
    }
}

module.exports = SharedArgumentNameHandler
