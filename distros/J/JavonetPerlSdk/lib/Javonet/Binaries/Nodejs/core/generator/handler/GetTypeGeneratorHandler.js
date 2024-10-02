const AbstractGeneratorHandler = require("./AbstractGeneratorHandler");
const SharedHandlerType = require("../internal/SharedHandlerType");
const OS = require("os");

class GetTypeGeneratorHandler extends AbstractGeneratorHandler {

    generate_code(existing_string_builder, common_command, used_object, handlers) {
        existing_string_builder.append(OS.EOL)
        existing_string_builder.append("const Javonet = require('Javonet');")
        existing_string_builder.append(OS.EOL)
        existing_string_builder.append("class ")
        handlers.SHARED_HANDLER[SharedHandlerType.CLASS_NAME].generate_code(existing_string_builder, common_command, used_object.payload[0], handlers)
        existing_string_builder.append(" {")
        existing_string_builder.append(OS.EOL)
        handlers.SHARED_HANDLER[SharedHandlerType.CLAZZ_INSTANCE].generate_code(existing_string_builder, common_command,
            used_object, handlers)
        existing_string_builder.append(OS.EOL)
        for (let i = 2; i < used_object.payload.length; i++) {
            handlers.GENERATOR_HANDLER[used_object.payload[i].commandType].generate_code(existing_string_builder, common_command, used_object.payload[i], handlers)
            existing_string_builder.append(OS.EOL)
        }
        existing_string_builder.append("}")
    }
}

module.exports = GetTypeGeneratorHandler