from javonet.core.handler.AbstractHandler import AbstractHandler
from javonet.core.handler.ValueHandler import ValueHandler
from javonet.core.handler.LoadLibraryHandler import LoadLibraryHandler
from javonet.core.handler.InvokeStaticMethodHandler import InvokeStaticMethodHandler
from javonet.core.handler.SetStaticFieldHandler import SetStaticFieldHandler
from javonet.core.handler.CreateClassInstanceHandler import CreateClassInstanceHandler
from javonet.core.handler.GetStaticFieldHandler import GetStaticFieldHandler
from javonet.core.handler.ResolveInstanceHandler import ResolveInstanceHandler
from javonet.core.handler.GetTypeHandler import GetTypeHandler
from javonet.core.handler.InvokeInstanceMethodHandler import InvokeInstanceMethodHandler
from javonet.core.handler.CastingHandler import CastingHandler
from javonet.core.handler.GetInstanceFieldHandler import GetInstanceFieldHandler
from javonet.core.handler.SetInstanceFieldHandler import SetInstanceFieldHandler
from javonet.core.handler.DestructReferenceHandler import DestructReferenceHandler
from javonet.core.handler.ArrayGetItemHandler import ArrayGetItemHandler
from javonet.core.handler.ArrayGetSizeHandler import ArrayGetSizeHandler
from javonet.core.handler.ArrayGetRankHandler import ArrayGetRankHandler
from javonet.core.handler.ArraySetItemHandler import ArraySetItemHandler
from javonet.core.handler.ArrayHandler import ArrayHandler
from javonet.core.handler.GetEnumItemHandler import GetEnumItemHandler
from javonet.core.handler.GetEnumNameHandler import GetEnumNameHandler
from javonet.core.handler.GetEnumValueHandler import GetEnumValueHandler
from javonet.core.handler.EnableNamespaceHandler import EnableNamespaceHandler
from javonet.core.handler.EnableTypeHandler import EnableTypeHandler
from javonet.core.handler.GetStaticMethodAsDelegateHandler import GetStaticMethodAsDelegateHandler
from javonet.core.handler.GetInstanceMethodAsDelegateHandler import GetInstanceMethodAsDelegateHandler
from javonet.core.handler.PassDelegateHandler import PassDelegateHandler
from javonet.core.handler.InvokeDelegateHandler import InvokeDelegateHandler


from javonet.core.handler.HandlerDictionary import handler_dict
from javonet.core.referenceCache.ReferencesCache import ReferencesCache
from javonet.utils.exception.ExceptionSerializer import ExceptionSerializer
from javonet.utils.CommandType import CommandType
from javonet.utils.Command import Command


class Handler(AbstractHandler):

    def __init__(self):
        handler_dict[CommandType.Value] = ValueHandler()
        handler_dict[CommandType.LoadLibrary] = LoadLibraryHandler()
        handler_dict[CommandType.InvokeStaticMethod] = InvokeStaticMethodHandler()
        handler_dict[CommandType.SetStaticField] = SetStaticFieldHandler()
        handler_dict[CommandType.CreateClassInstance] = CreateClassInstanceHandler()
        handler_dict[CommandType.GetStaticField] = GetStaticFieldHandler()
        handler_dict[CommandType.Reference] = ResolveInstanceHandler()
        handler_dict[CommandType.GetType] = GetTypeHandler()
        handler_dict[CommandType.InvokeInstanceMethod] = InvokeInstanceMethodHandler()
        handler_dict[CommandType.Cast] = CastingHandler()
        handler_dict[CommandType.GetInstanceField] = GetInstanceFieldHandler()
        handler_dict[CommandType.SetInstanceField] = SetInstanceFieldHandler()
        handler_dict[CommandType.DestructReference] = DestructReferenceHandler()
        handler_dict[CommandType.ArrayGetItem] = ArrayGetItemHandler()
        handler_dict[CommandType.ArrayGetSize] = ArrayGetSizeHandler()
        handler_dict[CommandType.ArrayGetRank] = ArrayGetRankHandler()
        handler_dict[CommandType.ArraySetItem] = ArraySetItemHandler()
        handler_dict[CommandType.Array] = ArrayHandler()
        handler_dict[CommandType.GetEnumItem] = GetEnumItemHandler()
        handler_dict[CommandType.GetEnumName] = GetEnumNameHandler()
        handler_dict[CommandType.GetEnumValue] = GetEnumValueHandler()
        handler_dict[CommandType.EnableNamespace] = EnableNamespaceHandler()
        handler_dict[CommandType.EnableType] = EnableTypeHandler()
        handler_dict[CommandType.GetStaticMethodAsDelegate] = GetStaticMethodAsDelegateHandler()
        handler_dict[CommandType.GetInstanceMethodAsDelegate] = GetInstanceMethodAsDelegateHandler()
        handler_dict[CommandType.PassDelegate] = PassDelegateHandler()
        handler_dict[CommandType.InvokeDelegate] = InvokeDelegateHandler()

    def handle_command(self, command):
        try:
            if command.command_type == CommandType.RetrieveArray:
                response_array = handler_dict[CommandType.Reference].handle_command(command.payload[0])
                return Command.create_array_response(response_array, command.runtime_name)

            response = handler_dict.get(command.command_type).handle_command(command)
            return self.__parse_response(response, command.runtime_name)
        except Exception as e:
            return ExceptionSerializer.serialize_exception(e, command)

    def __parse_response(self, response, runtime_name):
        if self.__is_response_simple_type(response) or self.__is_response_null(response):
            return Command.create_response(response, runtime_name)
        else:
            reference_cache = ReferencesCache()
            guid = reference_cache.cache_reference(response)
            return Command.create_reference(guid, runtime_name)

    @staticmethod
    def __is_response_simple_type(response):
        return isinstance(response, (int, float, bool, str))

    @staticmethod
    def __is_response_null(response):
        return response is None

    @staticmethod
    def __is_response_array(response):
        return isinstance(response, list);
