const generateGUID = require('../../utils/guid/generateGuid')

/**
 * A cache for storing and retrieving delegates.
 */
class DelegatesCache {
    cache = new Map()

    /**
     * Adds a delegate to the cache and returns its unique ID.
     * @param {Function} delegateInstance - The delegate function to store.
     * @returns {string} The unique ID for the delegate.
     */
    addDelegate(delegateInstance) {
        const delegateId = generateGUID()
        this.cache.set(delegateId, delegateInstance)
        return delegateId
    }

    /**
     * Retrieves a delegate by its unique ID.
     * @param {string} delegateId - The unique ID of the delegate.
     * @returns {Function} The delegate function.
     * @throws {Error} If the delegate is not found.
     */
    getDelegate(delegateId) {
        const delegateInstance = this.cache.get(delegateId)
        if (!delegateInstance) {
            throw new Error('Delegate not found')
        }
        return delegateInstance
    }
}

module.exports = new DelegatesCache()
