const ConnectionType = require('../ConnectionType')
const IConnectionData = require('./IConnectionData')

/**
 * @extends IConnectionData
 */
class InMemoryConnectionData extends IConnectionData {
    constructor() {
        super()
        this._connectionType = ConnectionType.IN_MEMORY
        this._hostname = ''
    }

    get connectionType() {
        return this._connectionType
    }

    get hostname() {
        return this._hostname
    }

    serializeConnectionData() {
        return [this.connectionType, 0, 0, 0, 0, 0, 0]
    }

    /**
     * @param {InMemoryConnectionData} other
     * @returns {boolean}
     */
    equals(other) {
        return other instanceof InMemoryConnectionData
    }
}

module.exports = InMemoryConnectionData
