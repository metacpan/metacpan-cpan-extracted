const AbstractHandler = require('./AbstractHandler')

/**
 * Handles retrieving an instance method as a delegate.
 */
class GetInstanceMethodAsDelegateHandler extends AbstractHandler {
    constructor() {
        super()
        /** @type {Function|null} */
        this.method = null
        /** @type {number} */
        this.requiredParametersCount = 2
        /** @type {Array<*>} */
        this.args = []
        /** @type {Object|null} */
        this.instance = null
    }

    /**
     * Processes a command to retrieve an instance method as a delegate.
     * @param {Object} command - The command containing payload data.
     * @param {Array<*>} command.payload - The payload containing instance, method name, and arguments.
     * @returns {Function} The delegate for the instance method.
     * @throws {Error} If the parameters mismatch or the method cannot be found.
     */
    process(command) {
        if (command.payload.length < this.requiredParametersCount) {
            throw new Error(`${this.constructor.name} parameters mismatch`)
        }

        this.instance = command.payload[0]
        const methodName = command.payload[1]
        this.args = command.payload.length > 2 ? command.payload.slice(2) : []

        // Find the method on the instance
        this.method = this.getMethod(this.instance, methodName)
        if (!this.method) {
            throw this.createMethodNotFoundError(this.instance, methodName)
        }

        // Create a delegate from the method
        const methodDelegate = this.method.bind(this.instance)
        return methodDelegate
    }

    /**
     * Retrieves the method from the type.
     * @param {Object} type - The class or constructor to search for the method.
     * @param {string} methodName - The name of the method.
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
        const methods = Object.getOwnPropertyNames(type.prototype).filter(
            (key) => typeof type.prototype[key] === 'function'
        )
        const availableMethods = methods.map((name) => `${name}()`)
        const message = `Method ${methodName} not found in class ${type.name}. Available instance public methods:\n${availableMethods.join('\n')}`
        return new Error(message)
    }
}

module.exports = new GetInstanceMethodAsDelegateHandler()
