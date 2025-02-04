const JsonFileResolver = require('./tools/JsonFileResolver')
const Transmitter = require('../core/transmitter/Transmitter')

const {
    RuntimeName,
    RuntimeNameHandler,
    InMemoryConnectionData,
    WsConnectionData,
    RuntimeContext,
} = require('../..')
const TcpConnectionData = require('../utils/connectionData/TcpConnectionData')

/**
 * The ConfigRuntimeFactory class provides methods for creating runtime contexts.
 * Each method corresponds to a specific runtime (CLR, JVM, .NET Core, Perl, Ruby, Node.js, Python) and returns a RuntimeContext instance for that runtime.
 * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/runtime-context)
 */
class ConfigRuntimeFactory {
    constructor(path) {
        this.path = path
        Transmitter.setConfigSource(path)
    }

    /**
     * Creates RuntimeContext instance to interact with the .NET Framework runtime.
     * @param {string} [configName="default"] - The name of the configuration to use (optional).
     * @return {RuntimeContext} a RuntimeContext instance for the .NET Framework runtime
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/runtime-context)
     */
    clr(configName = 'default') {
        return this.#getRuntimeContext(RuntimeName.Clr, configName)
    }

    /**
     * Creates RuntimeContext instance to interact with the JVM runtime.
     * @param {string} [configName="default"] - The name of the configuration to use (optional).
     * @return {RuntimeContext} a RuntimeContext instance for the JVM runtime
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/runtime-context)
     */
    jvm(configName = 'default') {
        return this.#getRuntimeContext(RuntimeName.Jvm, configName)
    }

    /**
     * Creates RuntimeContext instance to interact with the .NET runtime.
     * @param {string} [configName="default"] - The name of the configuration to use (optional).
     * @return {RuntimeContext} a RuntimeContext instance for the .NET runtime
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/runtime-context)
     */
    netcore(configName = 'default') {
        return this.#getRuntimeContext(RuntimeName.Netcore, configName)
    }

    /**
     * Creates RuntimeContext instance to interact with the Perl runtime.
     * @param {string} [configName="default"] - The name of the configuration to use (optional).
     * @return {RuntimeContext} a RuntimeContext instance for the Perl runtime
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/runtime-context)
     */
    perl(configName = 'default') {
        return this.#getRuntimeContext(RuntimeName.Perl, configName)
    }

    /**
     * Creates RuntimeContext instance to interact with the Python runtime.
     * @param {string} [configName="default"] - The name of the configuration to use (optional).
     * @return {RuntimeContext} a RuntimeContext instance for the Python runtime
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/runtime-context)
     */
    python(configName = 'default') {
        return this.#getRuntimeContext(RuntimeName.Python, configName)
    }

    /**
     * Creates RuntimeContext instance to interact with the Ruby runtime.
     * @param {string} [configName="default"] - The name of the configuration to use (optional).
     * @return {RuntimeContext} a RuntimeContext instance for the Ruby runtime
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/runtime-context)
     */
    ruby(configName = 'default') {
        return this.#getRuntimeContext(RuntimeName.Ruby, configName)
    }

    /**
     * Creates RuntimeContext instance to interact with Node.js runtime.
     * @param {string} [configName="default"] - The name of the configuration to use (optional).
     * @return {RuntimeContext} a RuntimeContext instance for the Node.js runtime
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/runtime-context)
     */
    nodejs(configName = 'default') {
        return this.#getRuntimeContext(RuntimeName.Nodejs, configName)
    }

    #getRuntimeContext(runtime, configName = 'default') {
        let jfr = new JsonFileResolver(this.path)

        try {
            let licenseKey = jfr.getLicenseKey()
            Transmitter.activateWithCredentials(licenseKey)
            // eslint-disable-next-line no-unused-vars
        } catch (error) {
            // licenseKey not found - do nothing
        }
        let rtmCtx = null
        let connData = null
        let connType = jfr.getChannelType(RuntimeNameHandler.getName(runtime), configName)
        if (connType === 'inMemory') {
            connData = new InMemoryConnectionData()
        } else if (connType === 'tcp') {
            connData = new TcpConnectionData(
                jfr.getChannelHost(RuntimeNameHandler.getName(runtime), configName),
                jfr.getChannelPort(RuntimeNameHandler.getName(runtime), configName)
            )
        } else if (connType === 'webSocket') {
            connData = new WsConnectionData(
                jfr.getChannelHost(RuntimeNameHandler.getName(runtime), configName)
            )
        } else {
            throw new Error('Unsupported connection type: ' + connType)
        }

        rtmCtx = RuntimeContext.getInstance(runtime, connData)
        this.#loadModules(runtime, configName, jfr, rtmCtx)
        return rtmCtx
    }

    #loadModules(runtime, configName, jfr, rtmCtx) {
        const modules = jfr
            .getModules(RuntimeNameHandler.getName(runtime), configName)
            .split(',')
            .filter((module) => module.trim() !== '')

        const configDirectoryAbsolutePath = require('path').dirname(this.path)

        modules.forEach((module) => {
            if (require('path').isAbsolute(module)) {
                rtmCtx.loadLibrary(module)
            } else {
                rtmCtx.loadLibrary(require('path').join(configDirectoryAbsolutePath, module))
            }
        })
    }
}

module.exports = ConfigRuntimeFactory
