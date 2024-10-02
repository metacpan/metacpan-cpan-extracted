const AbstractHandler = require("./AbstractHandler");

class CreateClassInstanceHandler extends AbstractHandler {
  requiredParametersCount = 1;

  constructor() {
    super();
  }

  process(command) {
    try {
      if (command.payload.length < this.requiredParametersCount) {
        throw new Error("Create Class Instance parameters mismatch");
      }
      let clazz = command.payload[0];
      let constructorArguments = command.payload.slice(1);
      let instance = new clazz(...constructorArguments);
      if (typeof instance === "undefined") {
        let methods = Object.getOwnPropertyNames(type).filter(function (
          property
        ) {
          return typeof type[property] === "function";
        });
        let message = `Method 'constructor' not found in class. Available methods:\n`;
        methods.forEach((methodIter) => {
          message += `${methodIter}\n`;
        });
        throw new Error(message);
      } else {
        return instance;
      }
    } catch (error) {
      throw this.process_stack_trace(error, this.constructor.name);
    }
  }
}

module.exports = new CreateClassInstanceHandler();
