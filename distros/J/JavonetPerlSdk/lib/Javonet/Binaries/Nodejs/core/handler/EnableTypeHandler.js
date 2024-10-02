const AbstractHandler = require("./AbstractHandler");
const TypeCache = require("../typeCache/TypeCache");

class EnableTypeHandler extends AbstractHandler {
    requiredParametersCount = 1

    constructor() {
        super()
    }

    process(command) {
        try {
            if (command.payload.length < this.requiredParametersCount) {
                throw new Error("Get Type parameters mismatch")
            }
            const typeCache = new TypeCache();

            for (let payload of command.payload) {
                if (typeof payload === 'string') {
                    typeCache.cacheType(payload);
                }
                if (Array.isArray(payload)) {
                    for (let namespace_to_enable of payload) {
                        typeCache.cacheType(namespace_to_enable);
                    }
                }
            }
            return 0;

        } catch (error) {
            throw this.process_stack_trace(error, this.constructor.name)
        }

    }
}

module.exports = new EnableTypeHandler()