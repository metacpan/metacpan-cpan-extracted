let _cache = {}
let _instance = null
const v4 = require('../../utils/uuid/v4')

class ReferencesCache {

    static getInstance() {
        if (_instance === null) {
            _instance = new ReferencesCache()
        }
        return _instance
    }

    cacheReference(reference) {
        let id = v4()
        _cache[id] = reference
        return id
    }

    resolveReference(id) {
        return _cache[id]
    }

    deleteReference(referenceGuid) {
        delete _cache[referenceGuid]
        return 0;
    }
}

module.exports = ReferencesCache