const AbstractHandler = require("./AbstractHandler");
const NamespaceCache = require("../namespaceCache/NamespaceCache");

class EnableNamespaceHandler extends AbstractHandler {

    constructor() {
        super()
        this.requiredParametersCount = 1
    }

    process(command) {
        try {
            if (command.payload.length < this.requiredParametersCount) {
                throw new Error(this.constructor.name + " parameters mismatch")
            }
            const namespace_cache = new NamespaceCache();

            for (let payload of command.payload) {
                if (typeof payload === 'string') {
                    namespace_cache.cacheNamespace(payload);
                }
                if (Array.isArray(payload)) {
                    for (let namespace_to_enable of payload) {
                        namespace_cache.cacheNamespace(namespace_to_enable);
                    }
                }
            }
            return 0;

        } catch (error) {
            throw this.process_stack_trace(error, this.constructor.name)
        }

    }
}

module.exports = new EnableNamespaceHandler()