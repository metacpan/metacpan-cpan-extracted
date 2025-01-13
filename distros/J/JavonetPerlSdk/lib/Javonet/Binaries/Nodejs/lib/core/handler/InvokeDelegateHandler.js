const { DelegatesCache } = require('../../..')
const AbstractHandler = require('./AbstractHandler')

/**
 * Handles invoking a delegate by GUID.
 */
class InvokeDelegateHandler extends AbstractHandler {
    constructor() {
        super()
        /** @type {number} */
        this.requiredParametersCount = 1
    }

    /**
     * Processes a command to invoke a delegate.
     * @param {Command} command - The command containing payload data.
     * @returns {*} The result of the delegate invocation.
     * @throws {Error} If the parameters mismatch or the delegate cannot be found.
     */
    process(command) {
        const payload = command.payload
        if (payload.length < this.requiredParametersCount) {
            throw new Error(`${this.constructor.name} parameters mismatch`)
        }

        const guid = payload[0]
        const delegate = DelegatesCache.getDelegate(guid)
        if (!delegate) {
            throw new Error('Delegate not found in cache')
        }

        return delegate
    }
}

module.exports = new InvokeDelegateHandler()
