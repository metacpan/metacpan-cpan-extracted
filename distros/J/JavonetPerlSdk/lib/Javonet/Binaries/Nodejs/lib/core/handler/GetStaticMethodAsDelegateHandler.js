// eslint-disable-next-line no-unused-vars
const { Command } = require('../../..')
const AbstractHandler = require('./AbstractHandler')

/**
 * Handles retrieving a static method as a delegate.
 */
class GetStaticMethodAsDelegateHandler extends AbstractHandler {
    /** @type {Array<*>} */
    args = []

    constructor() {
        super()
        /** @type {Function|null} */
        this.method = null
        /** @type {number} */
        this.requiredParametersCount = 2
    }

    /**
     * Processes a command to retrieve a static method as a delegate.
     * @param {Command} command - The command containing payload data.
     * @param {Array<*>} command.payload - The payload containing type, method name, and arguments.
     * @returns {Function} The delegate for the static method.
     * @throws {Error} If the parameters mismatch or the method cannot be found.
     */
    process(command) {
        if (command.payload.length < this.requiredParametersCount) {
            throw new Error(`${this.constructor.name} parameters mismatch`)
        }

        const type = command.payload[0]
        const methodName = command.payload[1]
        this.args = command.payload.length > 2 ? command.payload.slice(2) : []

        // Find the method on the type
        this.method = this.getMethod(type, methodName)
        if (!this.method) {
            throw this.createMethodNotFoundError(type, methodName)
        }

        // Create a delegate from the method
        const methodDelegate = this.method.bind(this)
        return methodDelegate
    }

    /**
     * Retrieves the method from the type.
     * @param {Object} type - The class or constructor to search for the method.
     * @param {string} methodName - The name of the method.
     * @param {Array<Function>} argsType - The argument types.
     * @param {Object} modifier - Parameter modifier (not used in JS implementation).
     * @returns {Function|null} The found method or null if not found.
     */
    getMethod(type, methodName) {
        const method = type[methodName]
        return typeof method === 'function' ? method : null
    }

    /**
     * Creates an error message when the method is not found.
     * @param {Object} type - The class or constructor.
     * @param {string} methodName - The method name.
     * @returns {Error} The error with detailed message.
     */
    createMethodNotFoundError(type, methodName) {
        const methods = Object.keys(type).filter((key) => typeof type[key] === 'function')
        const availableMethods = methods.map((name) => `${name}()`)
        const message = `Method ${methodName} not found in class ${type.name}. Available public static methods:\n${availableMethods.join('\n')}`
        return new Error(message)
    }
}

module.exports = new GetStaticMethodAsDelegateHandler()
