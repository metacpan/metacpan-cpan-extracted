const AbstractGeneratorHandler = require("../AbstractGeneratorHandler");

class SharedReturnTypeHandler extends AbstractGeneratorHandler {

    generate_code(existing_string_builder, common_command, used_object, handlers) {
        existing_string_builder.append("return ")
    }
}

module.exports = SharedReturnTypeHandler