const AbstractHandler = require("./AbstractHandler");

class SetStaticFieldHandler extends AbstractHandler {
  requiredParametersCount = 3;

  constructor() {
    super();
  }

  process(command) {
    try {
      if (command.payload.length < this.requiredParametersCount) {
        throw new Error("Set static field parameters mismatch");
      }
      const { payload } = command;
      let [obj, field, value] = payload;
      if (typeof obj[field] === "undefined") {
        let fields = Object.keys(obj);
        let message = `Field ${field} not found in class ${obj.constructor.name}. Available fields:\n`;
        fields.forEach((fieldIter) => {
          message += `${fieldIter}\n`;
        });
        throw new Error(message);
      }
      obj[field] = value;
      return 0;
    } catch (error) {
      throw this.process_stack_trace(error, this.constructor.name);
    }
  }
}

module.exports = new SetStaticFieldHandler();
