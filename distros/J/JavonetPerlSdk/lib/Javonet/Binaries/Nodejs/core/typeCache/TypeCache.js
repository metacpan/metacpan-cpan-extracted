class TypeCache {
    static _instance = null;
    typeCache = [];

    constructor() {
        if (TypeCache._instance === null) {
            TypeCache._instance = this;
        }
        return TypeCache._instance;
    }

    cacheType(typRegex) {
        this.typeCache.push(typRegex);
    }

    isTypeCacheEmpty() {
        return this.typeCache.length === 0;
    }

    isTypeAllowed(typeToCheck) {
        for (let pattern of this.typeCache) {
            if (new RegExp(pattern).test(typeToCheck.name)) {
                return true;
            }
        }
        return false;
    }

    getCachedTypes() {
        return this.typeCache;
    }

    clearCache() {
        this.typeCache = [];
        return 0;
    }
}

module.exports = TypeCache;