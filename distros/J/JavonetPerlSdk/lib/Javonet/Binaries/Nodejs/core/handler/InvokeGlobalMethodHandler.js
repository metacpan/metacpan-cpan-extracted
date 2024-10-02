const AbstractHandler = require("./AbstractHandler");

class InvokeGlobalMethodHandler extends AbstractHandler {
  requiredParametersCount = 1;

  constructor() {
    super();
  }

  process(command) {
    try {
      if (command.payload.length < this.requiredParametersCount) {
        throw new Error("Invoke Global Method parameters mismatch");
      }
      const { payload } = command;
      const splitted = payload[0].split(".");
      let methodToInvoke;
      for (let i = 0; i < splitted.length; i++) {
        methodToInvoke = !methodToInvoke
          ? global[splitted[i]]
          : methodToInvoke[splitted[i]];
      }
      if (typeof methodToInvoke === "undefined") {
        let methods = Object.getOwnPropertyNames(global).filter(function (
          property
        ) {
          return typeof global[property] === "function";
        });
        let message = `Method ${payload[0]} not found in global. Available methods:\n`;
        methods.forEach((methodIter) => {
          message += `${methodIter}\n`;
        });
        throw new Error(message);
      }
      if (payload.length > 1) {
        const args = payload.slice(1);
        return methodToInvoke(args);
      } else {
        return methodToInvoke();
      }
    } catch (error) {
      throw this.process_stack_trace(error, this.constructor.name);
    }
  }
}

module.exports = new InvokeGlobalMethodHandler();
