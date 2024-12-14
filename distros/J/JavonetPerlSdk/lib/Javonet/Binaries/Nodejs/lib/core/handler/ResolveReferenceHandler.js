const ReferencesCache = require('../referenceCache/ReferencesCache')
const AbstractHandler = require('./AbstractHandler')
class ResolveReferenceHandler extends AbstractHandler {
    constructor() {
        super()
    }

    process(command) {
        return ReferencesCache.getInstance().resolveReference(command.payload[0])
    }
}

module.exports = new ResolveReferenceHandler()
