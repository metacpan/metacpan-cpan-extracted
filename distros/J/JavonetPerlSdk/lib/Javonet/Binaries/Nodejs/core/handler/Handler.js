const CommandType = require('../../utils/CommandType')
const Command = require("../../utils/Command");
const ReferenceCache = require('../referenceCache/ReferencesCache')
const ExceptionSerializer = require('../../utils/exception/ExceptionSerializer')

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
const DestructReferenceHandler = require("./DestructReferenceHandler");
const CastHandler = require('./CastingHandler')
const InvokeGlobalMethodHandler = require('./InvokeGlobalMethodHandler')
const ArrayGetItemHandler = require('./ArrayGetItemHandler')
const ArrayGetSizeHandler = require('./ArrayGetSizeHandler')
const ArrayGetRankHandler = require('./ArrayGetRankHandler')
const ArraySetItemHandler = require('./ArraySetItemHandler')
const ArrayHandler = require('./ArrayHandler')
const EnableNamespaceHandler = require('./EnableNamespaceHandler')
const EnableTypeHandler = require('./EnableTypeHandler')


function isResponseSimpleType(response) {
    let type = typeof (response)
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
    [CommandType.InvokeGlobalMethod]: InvokeGlobalMethodHandler,
    [CommandType.DestructReference]: DestructReferenceHandler,
    [CommandType.ArrayGetItem]: ArrayGetItemHandler,
    [CommandType.ArrayGetSize]: ArrayGetSizeHandler,
    [CommandType.ArrayGetRank]: ArrayGetRankHandler,
    [CommandType.ArraySetItem]: ArraySetItemHandler,
    [CommandType.Array]: ArrayHandler,
    [CommandType.EnableNamespace]: EnableNamespaceHandler,
    [CommandType.EnableType]: EnableTypeHandler
}

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
            let cache = ReferenceCache.getInstance()
            let uuid = cache.cacheReference(response)
            return Command.createReference(uuid, runtimeName)
        }
    }
}

module.exports.Handler = Handler
module.exports.handlers = handlers

