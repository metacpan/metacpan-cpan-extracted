// eslint-disable-next-line no-unused-vars
const { Interpreter, Command, CommandType, InMemoryConnectionData, DelegatesCache } = require('../../..')
const AbstractHandler = require('./AbstractHandler')

/**
 * PassDelegateHandler class responsible for processing a command to create a delegate.
 */
class PassDelegateHandler extends AbstractHandler {
    constructor() {
        super()
        /**
         * Minimum required parameters count for the command.
         * @type {number}
         */
        this.requiredParametersCount = 1
        this.interpreter = new Interpreter()
    }

    /**
     * Processes the given command to create and compile a delegate.
     * @param {Command} command - The command to process.
     * @returns {Function} The compiled delegate function.
     */
    process(command) {
        this.validateCommand(command)

        const delegateGuid = command.payload[0]
        const delegate = DelegatesCache.getDelegate(delegateGuid)

        return delegate
    }

    /**
     * Validates the command to ensure it has enough parameters.
     * @param {Command} command - The command to validate.
     */
    validateCommand(command) {
        if (command.payload.length < this.requiredParametersCount) {
            throw new Error('PassDelegateHandler parameters mismatch')
        }
    }

    /**
     * Retrieves the arguments from the command payload.
     * @param {Command} command - The command containing the payload.
     * @returns {Array} The extracted arguments.
     */
    getArguments(command) {
        return command.payload.length > 2 ? command.payload.slice(2) : []
    }

    /**
     * Extracts argument types from the arguments array.
     * @param {Array} args - The arguments array.
     * @returns {Array} The argument types.
     */
    getArgumentTypes(args) {
        return args.slice(0, -1).map((arg) => arg.constructor)
    }

    /**
     * Retrieves the return type from the arguments array.
     * @param {Array} args - The arguments array.
     * @returns {Function} The return type.
     */
    getReturnType(args) {
        return args[args.length - 1].constructor
    }

    /**
     * Creates parameter expressions from argument types.
     * @param {Array} argsTypes - The argument types.
     * @returns {Array} The parameter expressions.
     */
    createParameters(argsTypes) {
        return argsTypes.map((type, index) => ({ name: `arg${index}`, type }))
    }

    /**
     * Creates an array of arguments for the delegate.
     * @param {string} delegateGuid - The delegate identifier.
     * @param {Array} parameters - The parameter expressions.
     * @returns {Array} The arguments array.
     */
    createArgsArray(delegateGuid, parameters) {
        return [delegateGuid, ...parameters.map((param) => param.name)]
    }

    /**
     * Creates a command expression.
     * @param {string} callingRuntimeName - The runtime name.
     * @param {Array} payload - The arguments array.
     * @returns {Object} The command object.
     */
    createCommand(callingRuntimeName, payload) {
        return {
            runtimeName: callingRuntimeName,
            type: CommandType.InvokeDelegate,
            payload,
        }
    }

    /**
     * Creates a method call to execute the command.
     * @param {Command} command - The command object.
     * @returns {Object} The response object.
     */
    createExecuteCall(command) {
        return this.interpreter.execute(command, new InMemoryConnectionData())
    }

    /**
     * Retrieves the response payload from the execution call.
     * @param {Object} executeCall - The execution call.
     * @returns {Array} The response payload.
     */
    getResponse(executeCall) {
        return executeCall.payload
    }

    /**
     * Converts the first element of the response to the return type.
     * @param {Array} response - The response payload.
     * @param {Function} returnType - The return type.
     * @returns {*} The converted first element.
     */
    convertFirstElement(response, returnType) {
        return returnType(response[0])
    }

    /**
     * Creates a block of expressions for the delegate.
     * @param {Function} returnType - The return type.
     * @param {*} convertedFirstElement - The converted first element.
     * @returns {Object} The block expression.
     */
    createBlock(returnType, convertedFirstElement) {
        return { returnType, body: convertedFirstElement }
    }

    /**
     * Creates a delegate type.
     * @param {Array} parameters - The parameter expressions.
     * @param {Function} returnType - The return type.
     * @returns {Function} The delegate type.
     */
    createDelegateType(parameters, returnType) {
        return (...args) => {
            if (args.length !== parameters.length) {
                throw new Error('Invalid argument count.')
            }
            return returnType
        }
    }
}

module.exports = new PassDelegateHandler()
