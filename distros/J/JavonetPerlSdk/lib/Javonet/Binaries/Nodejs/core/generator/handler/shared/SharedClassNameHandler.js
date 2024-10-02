const AbstractGeneratorHandler = require("../AbstractGeneratorHandler");
const reserved = require("reserved-words");

class SharedClassNameHandler extends AbstractGeneratorHandler {

    generate_code(existing_string_builder, common_command, used_object, handlers) {

        used_object = used_object.substring(used_object.lastIndexOf(".") + 1);

        if (used_object.includes('#')) {
            used_object = used_object.replace("#", "");
        }

        if (used_object.includes('-')) {
            used_object = used_object.replace("-", "_");
        }

        if (this.is_numeric_char(used_object[0])) {
            let pos = 0;
            for (const [index, element] of used_object.entries()) {
                if (this.is_numeric_char(element)) {
                    pos = index
                }
                break
            }
            const new_str = used_object.slice(pos);
            used_object = new_str
        }

        if (used_object[0] === used_object[0].toUpperCase()) {
            used_object = used_object[0].toLowerCase() + used_object.slice(1)
        }

        if (!reserved.check(used_object)) {
            existing_string_builder.append(used_object)
        } else {
            throw ("SharedMethodNameHandlerError: Given name is not valid: " + used_object)
        }
    }

    is_numeric_char(c) {
        return /\d/.test(c);
    }
}

module.exports = SharedClassNameHandler