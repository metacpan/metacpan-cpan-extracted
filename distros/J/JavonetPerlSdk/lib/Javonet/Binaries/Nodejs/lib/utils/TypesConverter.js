/**
 * ConvertTypeHandler class handles the conversion of JType to Type.
 */
class ConvertTypeHandler {
    constructor() {
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

/**
 * TypesConverter class provides utilities for converting between types.
 */
class TypesConverter {
    /**
     * Converts a JavaScript type to a JType equivalent.
     * @param {Function} type - The JavaScript type.
     * @returns {number} The corresponding JType.
     */
    static convertTypeToJType(type) {
        switch (type) {
            case Boolean:
                return JType.Boolean
            case Number:
                return JType.Float // Assuming Number maps to Float
            case String:
                return JType.String
            case Object:
                return JType.Null // Assuming Object maps to Null
            default:
                return JType.Null
        }
    }

    /**
     * Converts a JType to a JavaScript type equivalent.
     * @param {number} type - The JType to convert.
     * @returns {Function} The corresponding JavaScript type.
     */
    static convertJTypeToType(type) {
        switch (type) {
            case JType.Boolean:
                return Boolean
            case JType.Float:
                return Number
            case JType.String:
                return String
            case JType.Null:
                return null
            default:
                return null
        }
    }
}

/**
 * Enum for JType mappings.
 * @readonly
 * @enum {number}
 */
const JType = {
    Boolean: 1,
    Float: 2,
    String: 3,
    Null: 4,
}

module.exports = { ConvertTypeHandler, TypesConverter, JType }
