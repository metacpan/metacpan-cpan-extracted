const AbstractHandler = require("./AbstractHandler");

class SetGlobalStaticFieldHandler extends AbstractHandler {
  requiredParametersCount = 2;

  constructor() {
    super();
  }

  process(command) {
    try {
      if (command.payload.length < this.requiredParametersCount) {
        throw new Error("Set gloabal static field parameters mismatch");
      }
      const { payload } = command;
      const splitted = payload[0].split(".");
      const value = payload[1];
      let fieldToSet;

      for (let i = 0; i < splitted.length; i++) {
        if (
          typeof (fieldToSet
            ? fieldToSet[splitted[i]]
            : global[splitted[i]]) === "undefined"
        ) {
          let fields = Object.keys(fieldToSet ? fieldToSet : global);
          let message = `Field ${splitted[i]} not found in object. Available fields:\n`;
          fields.forEach((fieldIter) => {
            message += `${fieldIter}\n`;
          });
          throw new Error(message);
        }
        fieldToSet = !fieldToSet
          ? global[splitted[i]]
          : fieldToSet[splitted[i]];
      }
      fieldToSet = value;
    } catch (error) {
      throw this.process_stack_trace(error, this.constructor.name);
    }
  }
}

module.exports = new SetGlobalStaticFieldHandler();
