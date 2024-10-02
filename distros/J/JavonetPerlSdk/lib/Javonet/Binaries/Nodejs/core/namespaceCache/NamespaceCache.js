class NamespaceCache {
    static _instance = null;
    namespaceCache = [];

    constructor() {
        if (NamespaceCache._instance === null) {
            NamespaceCache._instance = this;
        }
        return NamespaceCache._instance;
    }

    cacheNamespace(namespaceRegex) {
        this.namespaceCache.push(namespaceRegex);
    }

    isNamespaceCacheEmpty() {
        return this.namespaceCache.length === 0;
    }

    isTypeAllowed(typeToCheck) {
        for (let pattern of this.namespaceCache) {
            if (new RegExp(pattern).test(typeToCheck.constructor.name)) {
                return true;
            }
        }
        return false;
    }

    getCachedNamespaces() {
        return this.namespaceCache;
    }

    clearCache() {
        this.namespaceCache = [];
        return 0;
    }
}

module.exports = NamespaceCache;