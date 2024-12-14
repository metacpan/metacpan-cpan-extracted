const AbstractGeneratorHandler = require('../../AbstractGeneratorHandler')
const { RuntimeName } = require('../../../../../..')
const OS = require('os')
const StringUtils = require('../../../utils/StringUtils')

class SharedGetTypeBodyHandler extends AbstractGeneratorHandler {
    generate_code(existing_string_builder, common_command, used_object, handlers) {
        existing_string_builder.append('return Javonet.inMemory().')
        existing_string_builder.append(
            StringUtils.capitalizeFirstLetter(Object.keys(RuntimeName)[common_command.runtimeName])
        )
        existing_string_builder.append('().')
        existing_string_builder.append('getType("')
        existing_string_builder.append(used_object.payload[0])
        existing_string_builder.append('").')
        existing_string_builder.append('execute()')
        existing_string_builder.append(OS.EOL)
    }
}

module.exports = SharedGetTypeBodyHandler
