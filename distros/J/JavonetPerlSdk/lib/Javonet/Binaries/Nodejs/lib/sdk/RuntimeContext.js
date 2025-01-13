/* eslint-disable valid-typeof */
const Interpreter = require('../core/interpreter/Interpreter')
const Command = require('../utils/Command')
const CommandType = require('../utils/CommandType')
const { InvocationContext, InvocationWsContext } = require('./InvocationContext')
const ConnectionType = require('../utils/ConnectionType')
const ExceptionThrower = require('../utils/exception/ExceptionThrower')
const DelegatesCache = require('../core/delegatesCache/DelegatesCache')
const RuntimeName = require('../utils/RuntimeName')

/**
 * Represents a single context which allows interaction with a selected technology.
 * Refers to a single instance of the called runtime within a particular target OS process.
 * This can be either the local currently running process (inMemory) or a particular remote process identified by the IP Address and PORT of the target Javonet instance.
 * Multiple Runtime Contexts can be initialized within one process.
 * Calling the same technology on inMemory communication channel will return the existing instance of runtime context.
 * Calling the same technology on TCP channel but on different nodes will result in unique Runtime Contexts.
 * Within the runtime context, any number of libraries can be loaded and any objects from the target technology can be interacted with, as they are aware of each other due to sharing the same memory space and same runtime instance.
 * @see [Javonet Guides]{@link https://www.javonet.com/guides/v2/javascript/foundations/runtime-context}
 * @class
 */
class RuntimeContext {
    static memoryRuntimeContexts = new Map()
    static networkRuntimeContexts = new Map()
    static webSocketRuntimeContexts = new Map()
    #currentCommand
    #responseCommand
    #interpreter
    // eslint-disable-next-line no-unused-private-class-members
    #generatorHandler

    constructor(runtimeName, connectionData) {
        this.runtimeName = runtimeName
        this.connectionData = connectionData
        this.#currentCommand = null
        this.#responseCommand = null
        this.#interpreter = new Interpreter()
        this.#generatorHandler = RuntimeContext.getGeneratorHandler()
    }

    static getGeneratorHandler() {
        try {
            const GeneratorHandler = require(require.resolve('../core/generator/handler/GeneratorHandler'))
            if (GeneratorHandler) {
                return new GeneratorHandler()
            }
            // eslint-disable-next-line no-unused-vars
        } catch (error) {
            // TODO: handle evnvs switch
        }
    }

    static getInstance(runtimeName, connectionData) {
        switch (connectionData.connectionType) {
            case ConnectionType.IN_MEMORY:
                if (runtimeName in RuntimeContext.memoryRuntimeContexts) {
                    let runtimeCtx = RuntimeContext.memoryRuntimeContexts[runtimeName]
                    runtimeCtx.currentCommand = null
                    return runtimeCtx
                } else {
                    let runtimeCtx = new RuntimeContext(runtimeName, connectionData)
                    RuntimeContext.memoryRuntimeContexts[runtimeName] = runtimeCtx
                    return runtimeCtx
                }
            case ConnectionType.TCP: {
                let key1 = runtimeName + JSON.stringify(connectionData)
                if (key1 in RuntimeContext.networkRuntimeContexts) {
                    let runtimeCtx = RuntimeContext.networkRuntimeContexts[key1]
                    runtimeCtx.currentCommand = null
                    return runtimeCtx
                } else {
                    let runtimeCtx = new RuntimeContext(runtimeName, connectionData)
                    RuntimeContext.networkRuntimeContexts[key1] = runtimeCtx
                    return runtimeCtx
                }
            }
            case ConnectionType.WEB_SOCKET: {
                let key2 = runtimeName + JSON.stringify(connectionData)
                if (key2 in RuntimeContext.webSocketRuntimeContexts) {
                    let runtimeCtx = RuntimeContext.webSocketRuntimeContexts[key2]
                    runtimeCtx.currentCommand = null
                    return runtimeCtx
                } else {
                    let runtimeCtx = new RuntimeContext(runtimeName, connectionData)
                    RuntimeContext.webSocketRuntimeContexts[key2] = runtimeCtx
                    return runtimeCtx
                }
            }
            default:
                throw new Error('Invalid connection type')
        }
    }

    /**
     * Executes the current command. The initial state of RuntimeContext is non-materialized,
     * wrapping either a single command or a chain of recursively nested commands.
     * Commands become nested through each invocation of methods on RuntimeContext.
     * Each invocation triggers the creation of a new RuntimeContext instance wrapping the current command with a new parent command.
     * The developer can decide at any moment of the materialization for the context, taking full control of the chunks of the expression being transferred and processed on the target runtime.
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/foundations/execute-method)
     * @method
     */
    execute() {
        this.#responseCommand = this.#interpreter.execute(this.#currentCommand, this.connectionData)
        this.#currentCommand = null
        if (this.#responseCommand.commandType === CommandType.Exception) {
            throw ExceptionThrower.throwException(this.#responseCommand)
        }
    }

    /**
     * Adds a reference to a library. Javonet allows you to reference and use modules or packages written in various languages.
     * This method allows you to use any library from all supported technologies. The necessary libraries need to be referenced.
     * The argument is a relative or full path to the library. If the library has dependencies on other libraries, the latter needs to be added first.
     * After referencing the library, any objects stored in this package can be used. Use static classes, create instances, call methods, use fields and properties, and much more.
     * @param {string} libraryPath - The relative or full path to the library.
     * @returns {RuntimeContext} RuntimeContext instance.
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/getting-started/adding-references-to-libraries)
     * @method
     */
    loadLibrary(libraryPath) {
        let localCommand = new Command(this.runtimeName, CommandType.LoadLibrary, [libraryPath])
        this.#currentCommand = this.#buildCommand(localCommand)
        this.execute()
        return this
    }

    /**
     * Retrieves a reference to a specific type. The type can be a class, interface or enum. The type can be retrieved from any referenced library.
     * @param {string} typeName - The full name of the type.
     * @param {...any} args - The arguments to be passed, if needed
     * @returns {InvocationContext} InvocationContext instance, that wraps the command to get the type.
     * @method
     */
    getType(typeName, ...args) {
        let localCommand = new Command(this.runtimeName, CommandType.GetType, [typeName, ...args])
        this.#currentCommand = null
        if (this.connectionData.connectionType === ConnectionType.WEB_SOCKET) {
            return new InvocationWsContext(
                this.runtimeName,
                this.connectionData,
                this.#buildCommand(localCommand)
            )
        }
        return new InvocationContext(this.runtimeName, this.connectionData, this.#buildCommand(localCommand))
    }

    /**
     * Casts the provided value to a specific type. This method is used when invoking methods that require specific types of arguments.
     * The arguments include the target type and the value to be cast. The target type must be retrieved from the called runtime using the getType method.
     * After casting the value, it can be used as an argument when invoking methods.
     * @param {...any} args - The target type and the value to be cast.
     * @returns {InvocationContext} InvocationContext instance that wraps the command to cast the value.
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/casting/casting)
     * @method
     */
    cast(...args) {
        let localCommand = new Command(this.runtimeName, CommandType.Cast, args)
        this.#currentCommand = null
        if (this.connectionData.connectionType === ConnectionType.WEB_SOCKET) {
            return new InvocationWsContext(
                this.runtimeName,
                this.connectionData,
                this.#buildCommand(localCommand)
            )
        }
        return new InvocationContext(this.runtimeName, this.connectionData, this.#buildCommand(localCommand))
    }

    /**
     * Retrieves a specific item from an enum type. This method is used when working with enums from the called runtime.
     * The arguments include the enum type and the name of the item. The enum type must be retrieved from the called runtime using the getType method.
     * After retrieving the item, it can be used as an argument when invoking methods or for other operations.
     * @param {...any} args - The enum type and the name of the item.
     * @returns {InvocationContext} InvocationContext instance that wraps the command to get the enum item.
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/enums/using-enum-type)
     * @method
     */
    getEnumItem(...args) {
        let localCommand = new Command(this.runtimeName, CommandType.GetEnumItem, args)
        this.#currentCommand = null
        if (this.connectionData.connectionType === ConnectionType.WEB_SOCKET) {
            return new InvocationWsContext(
                this.runtimeName,
                this.connectionData,
                this.#buildCommand(localCommand)
            )
        }
        return new InvocationContext(this.runtimeName, this.connectionData, this.#buildCommand(localCommand))
    }

    /**
     * Creates a reference type argument that can be passed to a method with a ref parameter modifier. This method is used when working with methods from the called runtime that require arguments to be passed by reference.
     * The arguments include the value and optionally the type of the reference. The type must be retrieved from the called runtime using the getType method.
     * After creating the reference, it can be used as an argument when invoking methods.
     * @param {...any} args - The value and optionally the type of the reference.
     * @returns {InvocationContext} InvocationContext instance that wraps the command to create a reference as ref.
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/methods-arguments/passing-arguments-by-reference-with-ref-keyword)
     * @method
     */
    asRef(...args) {
        let localCommand = new Command(this.runtimeName, CommandType.AsRef, args)
        this.#currentCommand = null
        if (this.connectionData.connectionType === ConnectionType.WEB_SOCKET) {
            return new InvocationWsContext(
                this.runtimeName,
                this.connectionData,
                this.#buildCommand(localCommand)
            )
        }
        return new InvocationContext(this.runtimeName, this.connectionData, this.#buildCommand(localCommand))
    }

    /**
     * Creates a reference type argument that can be passed to a method with an out parameter modifier. This method is used when working with methods from the called runtime that require arguments to be passed by reference.
     * The arguments include the value and optionally the type of the reference. The type must be retrieved from the called runtime using the getType method.
     * After creating the reference, it can be used as an argument when invoking methods.
     * @param {...any} args - The value and optionally the type of the reference.
     * @returns {InvocationContext} InvocationContext instance that wraps the command to create a reference as out.
     * @see [Javonet Guides](https://www.javonet.com/guides/v2/javascript/methods-arguments/passing-arguments-by-reference-with-out-keyword |Passing Arguments by Reference with out Keyword Guide)
     * @method
     */
    asOut(...args) {
        let localCommand = new Command(this.runtimeName, CommandType.AsOut, args)
        this.#currentCommand = null
        if (this.connectionData.connectionType === ConnectionType.WEB_SOCKET) {
            return new InvocationWsContext(
                this.runtimeName,
                this.connectionData,
                this.#buildCommand(localCommand)
            )
        }
        return new InvocationContext(this.runtimeName, this.connectionData, this.#buildCommand(localCommand))
    }

    #buildCommand = function (command) {
        for (let i = 0; i < command.payload.length; i++) {
            command.payload[i] = this.#encapsulatePayloadItem(command.payload[i])
        }
        return command.prependArgToPayload(this.#currentCommand)
    }

    #encapsulatePayloadItem = function (payloadItem) {
        if (typeof payloadItem === 'Command' || payloadItem instanceof Command) {
            for (let i = 0; i < payloadItem.payload.length; i++) {
                payloadItem.payload[i] = this.#encapsulatePayloadItem(payloadItem.payload[i])
            }
            return payloadItem
        } else if (typeof payloadItem === 'InvocationContext' || payloadItem instanceof InvocationContext) {
            return payloadItem.get_current_command()
        } else if (payloadItem instanceof Array) {
            for (let i = 0; i < payloadItem.length; i++) {
                payloadItem[i] = this.#encapsulatePayloadItem(payloadItem[i])
            }
            return new Command(this.runtimeName, CommandType.Array, payloadItem)
        } else if (typeof payloadItem === 'function') {
            let newArray = new Array(payloadItem.length + 1)
            for (let i = 0; i < newArray.length; i++) {
                newArray[i] = 'object'
            }
            const args = [DelegatesCache.addDelegate(payloadItem), RuntimeName.Nodejs].push(...newArray);
            return new Command(this.runtimeName, CommandType.PassDelegate, args)
        } else {
            return new Command(this.runtimeName, CommandType.Value, [payloadItem])
        }
    }

    healthCheck() {
        let localCommand = new Command(this.runtimeName, CommandType.Value, ['health_check'])
        this.#currentCommand = this.#buildCommand(localCommand)
        this.execute()
    }
}

module.exports = RuntimeContext
