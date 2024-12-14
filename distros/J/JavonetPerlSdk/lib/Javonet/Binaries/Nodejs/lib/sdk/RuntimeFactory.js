const Runtime = require('../utils/RuntimeName')
const RuntimeContext = require('./RuntimeContext')

/**
 * The RuntimeFactory class provides methods for creating runtime contexts.
 * Each method corresponds to a specific runtime (CLR, JVM, .NET Core, Perl, Ruby, Node.js, Python) and returns a RuntimeContext instance for that runtime.
 * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/runtime-context)
 */
class RuntimeFactory {
    constructor(connectionData) {
        this.connectionData = connectionData
    }

    /**
     * Creates RuntimeContext instance to interact with the .NET Framework runtime.
     * @return {RuntimeContext} a RuntimeContext instance for the .NET Framework runtime
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/runtime-context)
     */
    clr() {
        return RuntimeContext.getInstance(Runtime.Clr, this.connectionData)
    }

    /**
     * Creates RuntimeContext instance to interact with the JVM runtime.
     * @return {RuntimeContext} a RuntimeContext instance for the JVM runtime
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/runtime-context)
     */
    jvm() {
        return RuntimeContext.getInstance(Runtime.Jvm, this.connectionData)
    }

    /**
     * Creates RuntimeContext instance to interact with the .NET runtime.
     * @return {RuntimeContext} a RuntimeContext instance for the .NET runtime
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/runtime-context)
     */
    netcore() {
        return RuntimeContext.getInstance(Runtime.Netcore, this.connectionData)
    }

    /**
     * Creates RuntimeContext instance to interact with the Perl runtime.
     * @return {RuntimeContext} a RuntimeContext instance for the Perl runtime
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/runtime-context)
     */
    perl() {
        return RuntimeContext.getInstance(Runtime.Perl, this.connectionData)
    }

    /**
     * Creates RuntimeContext instance to interact with the Python runtime.
     * @return {RuntimeContext} a RuntimeContext instance for the Python runtime
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/runtime-context)
     */
    python() {
        return RuntimeContext.getInstance(Runtime.Python, this.connectionData)
    }

    /**
     * Creates RuntimeContext instance to interact with the Ruby runtime.
     * @return {RuntimeContext} a RuntimeContext instance for the Ruby runtime
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/runtime-context)
     */
    ruby() {
        return RuntimeContext.getInstance(Runtime.Ruby, this.connectionData)
    }

    /**
     * Creates RuntimeContext instance to interact with Node.js runtime.
     * @return {RuntimeContext} a RuntimeContext instance for the Node.js runtime
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/runtime-context)
     */
    nodejs() {
        return RuntimeContext.getInstance(Runtime.Nodejs, this.connectionData)
    }
}

module.exports = RuntimeFactory
