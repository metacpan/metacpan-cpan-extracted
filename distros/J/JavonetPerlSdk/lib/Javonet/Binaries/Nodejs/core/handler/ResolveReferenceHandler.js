const AbstractHandler = require("./AbstractHandler");
const ReferenceCache = require("../referenceCache/ReferencesCache")

class ResolveReferenceHandler extends AbstractHandler {
    constructor() {
        super()
    }

    process(command) {
        return ReferenceCache.getInstance().resolveReference(command.payload[0])
    }
}

module.exports = new ResolveReferenceHandler()