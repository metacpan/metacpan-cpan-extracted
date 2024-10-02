from javonet.core.generator.handler.CreateInstanceGeneratorHandler import CreateInstanceGeneratorHandler
from javonet.core.generator.handler.GetInstanceFieldGeneratorHandler import GetInstanceFieldGeneratorHandler
from javonet.core.generator.handler.GetStaticFieldGeneratorHandler import GetStaticFieldGeneratorHandler
from javonet.core.generator.handler.GetTypeGeneratorHandler import GetTypeGeneratorHandler
from javonet.core.generator.handler.InvokeInstanceMethodGeneratorHandler import InvokeInstanceMethodGeneratorHandler
from javonet.core.generator.handler.InvokeStaticMethodGeneratorHandler import InvokeStaticMethodGeneratorHandler
from javonet.core.generator.handler.shared.body.SharedBodyHandler import SharedBodyHandler
from javonet.core.generator.handler.shared.body.SharedCreateInstanceBodyHandler import SharedCreateInstanceBodyHandler
from javonet.core.generator.handler.shared.body.SharedGetInstanceFieldBodyHandler import \
    SharedGetInstanceFieldBodyHandler
from javonet.core.generator.handler.shared.body.SharedGetStaticFieldBodyHandler import SharedGetStaticFieldBodyHandler
from javonet.core.generator.handler.shared.body.SharedGetTypeBodyHandler import SharedGetTypeBodyHandler
from javonet.core.generator.handler.shared.body.SharedInvokeInstanceMethodBodyHandler import \
    SharedInvokeInstanceMethodBodyHandler
from javonet.core.generator.handler.shared.body.SharedInvokeStaticMethodBodyHandler import \
    SharedInvokeStaticMethodBodyHandler
from javonet.utils.CommandType import CommandType

from javonet.core.generator.handler.shared.SharedArgumentNameHandler import SharedArgumentNameHandler
from javonet.core.generator.handler.shared.SharedClassInstanceHandler import SharedClassInstanceHandler
from javonet.core.generator.handler.shared.SharedClassNameHandler import SharedClassNameHandler
from javonet.core.generator.handler.shared.SharedMethodNameHandler import SharedMethodNameHandler
from javonet.core.generator.handler.shared.SharedModifierHandler import SharedModifierHandler
from javonet.core.generator.handler.shared.SharedReturnTypeHandler import SharedReturnTypeHandler
from javonet.core.generator.handler.shared.SharedTypeHandler import SharedTypeHandler
from javonet.core.generator.internal.SharedHandlerType import SharedHandlerType


class Handlers:

    types_to_analyze = []

    GENERATOR_HANDLER = dict()
    SHARED_HANDLER = dict()
    SHARED_BODY_HANDLER = dict()

    def __init__(self):
        self.SHARED_HANDLER[SharedHandlerType.ARGUMENT_NAME] = SharedArgumentNameHandler()
        self.SHARED_HANDLER[SharedHandlerType.METHOD_BODY] = SharedBodyHandler()
        self.SHARED_HANDLER[SharedHandlerType.CLASS_NAME] = SharedClassNameHandler()
        self.SHARED_HANDLER[SharedHandlerType.METHOD_NAME] = SharedMethodNameHandler()
        self.SHARED_HANDLER[SharedHandlerType.MODIFIER] = SharedModifierHandler()
        self.SHARED_HANDLER[SharedHandlerType.TYPE] = SharedTypeHandler()
        self.SHARED_HANDLER[SharedHandlerType.CLAZZ_INSTANCE] = SharedClassInstanceHandler()
        self.SHARED_HANDLER[SharedHandlerType.RETURN_TYPE] = SharedReturnTypeHandler()

        self.SHARED_BODY_HANDLER[CommandType.CreateClassInstance] = SharedCreateInstanceBodyHandler()
        self.SHARED_BODY_HANDLER[CommandType.GetType] = SharedGetTypeBodyHandler()
        self.SHARED_BODY_HANDLER[CommandType.InvokeInstanceMethod] = SharedInvokeInstanceMethodBodyHandler()
        self.SHARED_BODY_HANDLER[CommandType.InvokeStaticMethod] = SharedInvokeStaticMethodBodyHandler()
        self.SHARED_BODY_HANDLER[CommandType.GetStaticField] = SharedGetStaticFieldBodyHandler()
        self.SHARED_BODY_HANDLER[CommandType.GetInstanceField] = SharedGetInstanceFieldBodyHandler()

        self.GENERATOR_HANDLER[CommandType.CreateClassInstance] = CreateInstanceGeneratorHandler()
        self.GENERATOR_HANDLER[CommandType.GetType] = GetTypeGeneratorHandler()
        self.GENERATOR_HANDLER[CommandType.InvokeInstanceMethod] = InvokeInstanceMethodGeneratorHandler()
        self.GENERATOR_HANDLER[CommandType.InvokeStaticMethod] = InvokeStaticMethodGeneratorHandler()
        self.GENERATOR_HANDLER[CommandType.GetStaticField] = GetStaticFieldGeneratorHandler()
        self.GENERATOR_HANDLER[CommandType.GetInstanceField] = GetInstanceFieldGeneratorHandler()
