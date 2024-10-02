const AbstractGeneratorHandler = require("../../AbstractGeneratorHandler");
const StringUtils = require("../../../utils/StringUtils");
const CommonGenerator = require("../../../internal/CommonGenerator");
const SharedHandlerType = require("../../../internal/SharedHandlerType");
const RuntimeName = require("../../../../../utils/RuntimeName");
const OS = require("os");

class SharedInvokeStaticMethodBodyHandler extends AbstractGeneratorHandler {

    generate_code(existing_string_builder, common_command, used_object, handlers) {
        handlers.SHARED_HANDLER[SharedHandlerType.RETURN_TYPE].generate_code(existing_string_builder, common_command,
            used_object.payload[1],
            handlers)
        existing_string_builder.append("Javonet.inMemory().")
        existing_string_builder.append(StringUtils.capitalizeFirstLetter(Object.keys(RuntimeName)[common_command.runtimeName]))
        existing_string_builder.append("().")
        existing_string_builder.append("getType(\"")
        existing_string_builder.append(used_object.payload[3])
        existing_string_builder.append("\").")
        existing_string_builder.append("invokeStaticMethod(\"")
        existing_string_builder.append(used_object.payload[0])
        existing_string_builder.append("\", ")
        CommonGenerator.process_method_arguments_names(existing_string_builder, common_command,
            used_object.payload[5], handlers)
        existing_string_builder.append(").")
        existing_string_builder.append("execute().resultValue")
        existing_string_builder.append(OS.EOL)
    }
}

module.exports = SharedInvokeStaticMethodBodyHandler