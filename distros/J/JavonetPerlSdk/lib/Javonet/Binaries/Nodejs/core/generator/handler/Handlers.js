const SharedHandlerType = require("../internal/SharedHandlerType");
const CommandType = require("../../../utils/CommandType")
const SharedArgumentNameHandler = require("./shared/SharedArgumentNameHandler");
const SharedMethodNameHandler = require("./shared/SharedMethodNameHandler");
const SharedBodyHandler = require("./shared/body/SharedBodyHandler");
const SharedClassNameHandler = require("./shared/SharedClassNameHandler");
const SharedClassInstanceHandler = require("./shared/SharedClassInstanceHandler");
const SharedReturnTypeHandler = require("./shared/SharedReturnTypeHandler");
const SharedCreateInstanceBodyHandler = require("./shared/body/SharedCreateInstanceBodyHandler");
const SharedGetTypeBodyHandler = require("./shared/body/SharedGetTypeBodyHandler");
const SharedInvokeInstanceMethodBodyHandler = require("./shared/body/SharedInvokeInstanceMethodBodyHandler");
const SharedInvokeStaticMethodBodyHandler = require("./shared/body/SharedInvokeStaticMethodBodyHandler");
const SharedGetStaticFieldBodyHandler = require("./shared/body/SharedGetStaticFieldBodyHandler");
const SharedGetInstanceFieldBodyHandler = require("./shared/body/SharedGetInstanceFieldBodyHandler");
const CreateInstanceGeneratorHandler = require("./CreateInstanceGeneratorHandler");
const GetTypeGeneratorHandler = require("./GetTypeGeneratorHandler");
const InvokeInstanceMethodGeneratorHandler = require("./InvokeInstanceMethodGeneratorHandler");
const InvokeStaticMethodGeneratorHandler = require("./InvokeStaticMethodGeneratorHandler");
const GetStaticFieldGeneratorHandler = require("./GetStaticFieldGeneratorHandler");
const GetInstanceFieldGeneratorHandler = require("./GetInstanceFieldGeneratorHandler");

class Handlers {
    GENERATOR_HANDLER = {};
    SHARED_HANDLER = {};
    SHARED_BODY_HANDLER = {};

    constructor() {
        this.SHARED_HANDLER[SharedHandlerType.ARGUMENT_NAME] = new SharedArgumentNameHandler()
        this.SHARED_HANDLER[SharedHandlerType.METHOD_BODY] = new SharedBodyHandler()
        this.SHARED_HANDLER[SharedHandlerType.CLASS_NAME] = new SharedClassNameHandler()
        this.SHARED_HANDLER[SharedHandlerType.METHOD_NAME] = new SharedMethodNameHandler()
        this.SHARED_HANDLER[SharedHandlerType.CLAZZ_INSTANCE] = new SharedClassInstanceHandler()
        this.SHARED_HANDLER[SharedHandlerType.RETURN_TYPE] = new SharedReturnTypeHandler()

        this.SHARED_BODY_HANDLER[CommandType.CreateClassInstance] = new SharedCreateInstanceBodyHandler()
        this.SHARED_BODY_HANDLER[CommandType.GetType] = new SharedGetTypeBodyHandler()
        this.SHARED_BODY_HANDLER[CommandType.InvokeInstanceMethod] = new SharedInvokeInstanceMethodBodyHandler()
        this.SHARED_BODY_HANDLER[CommandType.InvokeStaticMethod] = new SharedInvokeStaticMethodBodyHandler()
        this.SHARED_BODY_HANDLER[CommandType.GetStaticField] = new SharedGetStaticFieldBodyHandler()
        this.SHARED_BODY_HANDLER[CommandType.GetInstanceField] = new SharedGetInstanceFieldBodyHandler()

        this.GENERATOR_HANDLER[CommandType.CreateClassInstance] = new CreateInstanceGeneratorHandler()
        this.GENERATOR_HANDLER[CommandType.GetType] = new GetTypeGeneratorHandler()
        this.GENERATOR_HANDLER[CommandType.InvokeInstanceMethod] = new InvokeInstanceMethodGeneratorHandler()
        this.GENERATOR_HANDLER[CommandType.InvokeStaticMethod] = new InvokeStaticMethodGeneratorHandler()
        this.GENERATOR_HANDLER[CommandType.GetStaticField] = new GetStaticFieldGeneratorHandler()
        this.GENERATOR_HANDLER[CommandType.GetInstanceField] = new GetInstanceFieldGeneratorHandler()
    }
}

module.exports = Handlers