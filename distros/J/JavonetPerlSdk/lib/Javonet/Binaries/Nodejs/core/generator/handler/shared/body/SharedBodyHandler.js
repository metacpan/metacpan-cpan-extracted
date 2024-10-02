const AbstractGeneratorHandler = require("../../AbstractGeneratorHandler");
const os = require('os')

class SharedBodyHandler extends AbstractGeneratorHandler {

    generate_code(existing_string_builder, common_command, used_object, handlers) {
        existing_string_builder.append("{");
        existing_string_builder.append(os.EOL);
        handlers.SHARED_BODY_HANDLER[used_object.commandType].generate_code(existing_string_builder, common_command, used_object, handlers)
        existing_string_builder.append("}");
    }
}

module.exports = SharedBodyHandler