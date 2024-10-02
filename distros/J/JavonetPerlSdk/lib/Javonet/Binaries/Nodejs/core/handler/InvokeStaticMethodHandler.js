const AbstractHandler = require("./AbstractHandler");

class InvokeStaticMethodHandler extends AbstractHandler {
  requiredParametersCount = 2;

  constructor() {
    super();
  }

  process(command) {
    try {
      if (command.payload.length < this.requiredParametersCount) {
        throw new Error("Invoke Static Method parameters mismatch");
      }
      const { payload } = command;
      let type = payload[0];
      let methodName = payload[1];
      let args = payload.slice(2);
      let method = type[methodName];
      if (typeof method === "undefined") {
        let methods = Object.getOwnPropertyNames(type).filter(function (
          property
        ) {
          return typeof type[property] === "function";
        });
        let message = `Method ${methodName} not found in class. Available methods:\n`;
        methods.forEach((methodIter) => {
          message += `${methodIter}\n`;
        });
        throw new Error(message);
      } else {
        return Reflect.apply(method, undefined, args);
      }
    } catch (error) {
      throw this.process_stack_trace(error, this.constructor.name);
    }
  }
}

module.exports = new InvokeStaticMethodHandler();
