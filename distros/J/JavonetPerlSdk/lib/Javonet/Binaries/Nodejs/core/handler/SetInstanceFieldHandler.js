const AbstractHandler = require("./AbstractHandler");

class SetInstanceFieldHandler extends AbstractHandler {
  requiredParametersCount = 3;

  constructor() {
    super();
  }

  process(command) {
    try {
      if (command.payload.length < this.requiredParametersCount) {
        throw new Error("Set Instance Field parameters mismatch");
      }
      const { payload } = command;
      let instance = payload[0];
      let field = payload[1];
      let value = payload[2];
      if (typeof instance[field] === "undefined") {
        let fields = Object.keys(instance);
        let message = `Field ${field} not found in object. Available fields:\n`;
        fields.forEach((fieldIter) => {
          message += `${fieldIter}\n`;
        });
        throw new Error(message);
      }
      instance[field] = value;
      return 0;
    } catch (error) {
      throw this.process_stack_trace(error, this.constructor.name);
    }
  }
}

module.exports = new SetInstanceFieldHandler();
