const AbstractGeneratorHandler = require("../AbstractGeneratorHandler");
const OS = require("os");

class SharedClassInstanceHandler extends AbstractGeneratorHandler {

    generate_code(existing_string_builder, common_command, used_object, handlers) {
        existing_string_builder.append(OS.EOL)
        existing_string_builder.append("instance = null")
        existing_string_builder.append(OS.EOL)
    }
}

module.exports = SharedClassInstanceHandler