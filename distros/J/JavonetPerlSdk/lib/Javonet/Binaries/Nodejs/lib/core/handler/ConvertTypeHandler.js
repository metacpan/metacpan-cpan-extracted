const { TypesConverter } = require('../../utils/TypesConverter')
const AbstractHandler = require('./AbstractHandler')

/**
 * ConvertTypeHandler class handles the conversion of JType to Type.
 */
class ConvertTypeHandler extends AbstractHandler {
    constructor() {
        super()
        /**
         * Minimum required parameters count for the command.
         * @type {number}
         */
        this.requiredParametersCount = 1
    }

    /**
     * Processes the given command to convert JType to Type.
     * @param {Object} command - The command to process.
     * @returns {any} The converted type.
     */
    process(command) {
        this.validateCommand(command)
        return TypesConverter.convertJTypeToType(command.payload[0])
    }

    /**
     * Validates the command to ensure it has enough parameters.
     * @param {Object} command - The command to validate.
     */
    validateCommand(command) {
        if (command.payload.length < this.requiredParametersCount) {
            throw new Error('ConvertTypeHandler parameters mismatch')
        }
    }
}

module.exports = ConvertTypeHandler
