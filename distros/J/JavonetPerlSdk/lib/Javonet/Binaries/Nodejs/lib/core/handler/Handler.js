const ValueHandler = require('./ValueHandler')
const LoadLibraryHandler = require('./LoadLibraryHandler')
const GetTypeHandler = require('./GetTypeHandler')
const InvokeStaticMethodHandler = require('./InvokeStaticMethodHandler')
const GetStaticFieldHandler = require('./GetStaticFieldHandler')
const SetStaticFieldHandler = require('./SetStaticFieldHandler')
const ResolveReferenceHandler = require('./ResolveReferenceHandler')
const CreateClassInstanceHandler = require('./CreateClassInstanceHandler')
const GetInstanceFieldHandler = require('./GetInstanceFieldHandler')
const SetInstanceFieldHandler = require('./SetInstanceFieldHandler')
const InvokeInstanceMethodHandler = require('./InvokeInstanceMethodHandler')
const DestructReferenceHandler = require('./DestructReferenceHandler')
const CastHandler = require('./CastingHandler')
const InvokeGlobalMethodHandler = require('./InvokeGlobalMethodHandler')
const ArrayGetItemHandler = require('./ArrayGetItemHandler')
const ArrayGetSizeHandler = require('./ArrayGetSizeHandler')
const ArrayGetRankHandler = require('./ArrayGetRankHandler')
const ArraySetItemHandler = require('./ArraySetItemHandler')
const ArrayHandler = require('./ArrayHandler')
const EnableNamespaceHandler = require('./EnableNamespaceHandler')
const EnableTypeHandler = require('./EnableTypeHandler')

const { CommandType, Command, ExceptionSerializer } = require('../../..')
const ReferencesCache = require('../referenceCache/ReferencesCache')
const InvokeStandaloneMethodHandler = require('./InvokeStandaloneMethodHandler')
const GetStaticMethodAsDelegateHandler = require('./GetStaticMethodAsDelegateHandler')
const GetInstanceMethodAsDelegateHandler = require('./GetInstanceMethodAsDelegateHandler')
const PassDelegateHandler = require('./PassDelegateHandler')
const InvokeDelegateHandler = require('./InvokeDelegateHandler')
const { ConvertTypeHandler } = require('../../utils/TypesConverter')

function isResponseSimpleType(response) {
    let type = typeof response
    return ['string', 'boolean', 'number'].includes(type)
}

function isResponseNull(response) {
    return response === null
}

const handlers = {
    [CommandType.Value]: ValueHandler,
    [CommandType.LoadLibrary]: LoadLibraryHandler,
    [CommandType.InvokeStaticMethod]: InvokeStaticMethodHandler,
    [CommandType.GetType]: GetTypeHandler,
    [CommandType.GetStaticField]: GetStaticFieldHandler,
    [CommandType.SetStaticField]: SetStaticFieldHandler,
    [CommandType.CreateClassInstance]: CreateClassInstanceHandler,
    [CommandType.Reference]: ResolveReferenceHandler,
    [CommandType.Cast]: CastHandler,
    [CommandType.GetInstanceField]: GetInstanceFieldHandler,
    [CommandType.SetInstanceField]: SetInstanceFieldHandler,
    [CommandType.InvokeInstanceMethod]: InvokeInstanceMethodHandler,
    [CommandType.InvokeStandaloneMethod]: InvokeStandaloneMethodHandler,
    [CommandType.InvokeGlobalMethod]: InvokeGlobalMethodHandler,
    [CommandType.DestructReference]: DestructReferenceHandler,
    [CommandType.ArrayGetItem]: ArrayGetItemHandler,
    [CommandType.ArrayGetSize]: ArrayGetSizeHandler,
    [CommandType.ArrayGetRank]: ArrayGetRankHandler,
    [CommandType.ArraySetItem]: ArraySetItemHandler,
    [CommandType.Array]: ArrayHandler,
    [CommandType.EnableNamespace]: EnableNamespaceHandler,
    [CommandType.EnableType]: EnableTypeHandler,
    [CommandType.GetStaticMethodAsDelegate]: GetStaticMethodAsDelegateHandler,
    [CommandType.GetInstanceMethodAsDelegate]: GetInstanceMethodAsDelegateHandler,
    [CommandType.PassDelegate]: PassDelegateHandler,
    [CommandType.InvokeDelegate]: InvokeDelegateHandler,
    [CommandType.ConvertType]: ConvertTypeHandler,
}

Object.keys(handlers).forEach((commandTypeHandler) => {
    handlers[commandTypeHandler].handlers = handlers
})

class Handler {
    handleCommand(command) {
        try {
            if (command.commandType === CommandType.RetrieveArray) {
                let responseArray = handlers[CommandType.Reference].handleCommand(command.payload[0])
                return Command.createArrayResponse(responseArray, command.runtimeName)
            }
            let response = handlers[command.commandType].handleCommand(command)
            return this.parseCommand(response, command.runtimeName)
        } catch (error) {
            return ExceptionSerializer.serializeException(error, command)
        }
    }

    parseCommand(response, runtimeName) {
        if (isResponseNull(response) || isResponseSimpleType(response)) {
            return Command.createResponse(response, runtimeName)
        } else {
            let cache = ReferencesCache.getInstance()
            let uuid = cache.cacheReference(response)
            return Command.createReference(uuid, runtimeName)
        }
    }
}

module.exports.Handler = Handler
module.exports.handlers = handlers
