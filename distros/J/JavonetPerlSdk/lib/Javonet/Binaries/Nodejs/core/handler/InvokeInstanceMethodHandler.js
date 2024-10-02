const AbstractHandler = require("./AbstractHandler");

class InvokeInstanceMethodHandler extends AbstractHandler {
  requiredParametersCount = 2;

  constructor() {
    super();
  }

  process(command) {
    try {
      if (command.payload.length < this.requiredParametersCount) {
        throw new Error("Invoke Instance Method parameters mismatch");
      }
      const { payload } = command;
      let instance = payload[0];
      let methodName = payload[1];
      let args = payload.slice(2);
      let method = instance[methodName];
      if (typeof method === "undefined") {
        let methods = Object.getOwnPropertyNames(instance.__proto__).filter(
          function (property) {
            return typeof instance.__proto__[property] === "function";
          }
        );
        let message = `Method ${methodName} not found in object. Available methods:\n`;
        methods.forEach((methodIter) => {
          message += `${methodIter}\n`;
        });
        throw new Error(message);
      } else {
        return Reflect.apply(method, instance, args);
      }
    } catch (error) {
      throw this.process_stack_trace(error, this.constructor.name);
    }
  }
}

module.exports = new InvokeInstanceMethodHandler();
