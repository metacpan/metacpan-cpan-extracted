const AbstractHandler = require("./AbstractHandler");

class GetGlobalStaticFieldHandler extends AbstractHandler {
  requiredParametersCount = 1;

  constructor() {
    super();
  }

  process(command) {
    try {
      if (command.payload.length < this.requiredParametersCount) {
        throw new Error("Get global static field parameters mismatch");
      }
      const { payload } = command;
      const splitted = payload[0].split(".");
      let fieldToGet;

      for (let i = 0; i < splitted.length; i++) {
        fieldToGet = !fieldToGet
          ? global[splitted[i]]
          : fieldToGet[splitted[i]];
        if (typeof fieldToGet === "undefined") {
          let fields = Object.keys(global);
          let message = `Field ${payload[0]} not found in global. Available fields:\n`;
          fields.forEach((fieldIter) => {
            message += `${fieldIter}\n`;
          });
          throw new Error(message);
        }
      }
      return fieldToGet;
    } catch (error) {
      throw this.process_stack_trace(error, this.constructor.name);
    }
  }
}

module.exports = new GetGlobalStaticFieldHandler();
