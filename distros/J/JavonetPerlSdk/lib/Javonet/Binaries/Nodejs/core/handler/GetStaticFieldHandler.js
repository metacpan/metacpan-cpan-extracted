const AbstractHandler = require("./AbstractHandler");

class GetStaticFieldHandler extends AbstractHandler {
  requiredParametersCount = 2;

  constructor() {
    super();
  }

  process(command) {
    try {
      if (command.payload.length < this.requiredParametersCount) {
        throw new Error("Array Static Field parameters mismatch");
      }
      const { payload } = command;
      let type = payload[0];
      let field = payload[1];

      let staticField = type[field];
      if (typeof staticField === "undefined") {
        let fields = Object.keys(type);
        let message = `Field ${field} not found in class. Available fields:\n`;
        fields.forEach((fieldIter) => {
          message += `${fieldIter}\n`;
        });
        throw new Error(message);
      } else {
        return staticField;
      }
    } catch (error) {
      throw this.process_stack_trace(error, this.constructor.name);
    }
  }
}

module.exports = new GetStaticFieldHandler();
