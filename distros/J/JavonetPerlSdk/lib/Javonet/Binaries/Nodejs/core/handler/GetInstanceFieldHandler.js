const AbstractHandler = require("./AbstractHandler");

class GetInstanceFieldHandler extends AbstractHandler {
  requiredParametersCount = 2;

  constructor() {
    super();
  }

  process(command) {
    try {
      if (command.payload.length < this.requiredParametersCount) {
        throw new Error("Get Instance Field parameters mismatch");
      }
      const { payload } = command;
      let instance = payload[0];
      let field = payload[1];
      let instanceField = instance[field];
      if (typeof instanceField === "undefined") {
        let fields = Object.keys(instance);
        let message = `Field ${field} not found in object. Available fields:\n`;
        fields.forEach((fieldIter) => {
          message += `${fieldIter}\n`;
        });
        throw new Error(message);
      } else {
        return instanceField;
      }
    } catch (error) {
      throw this.process_stack_trace(error, this.constructor.name);
    }
  }
}

module.exports = new GetInstanceFieldHandler();
