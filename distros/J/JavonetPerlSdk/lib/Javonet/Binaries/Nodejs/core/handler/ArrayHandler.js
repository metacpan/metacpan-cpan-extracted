const AbstractHandler = require("./AbstractHandler")


class ArrayHandler extends AbstractHandler {
    constructor() {
        super()
    }

    process(command) {
        try {
            let processedArray = command.payload
            return processedArray
        } catch (error) {
            throw this.process_stack_trace(error, this.constructor.name)
        }
    }
}

module.exports = new ArrayHandler()