const AbstractHandler = require("./AbstractHandler")


class ArrayGetSizeHandler extends AbstractHandler {
    requiredParametersCount = 1

    constructor() {
        super()
    }

    process(command) {
        try {
            if (command.payload.length < this.requiredParametersCount) {
                throw new Error("Array Get Size parameters mismatch")
            }
            let array = command.payload[0]
            let size = 1
            while (Array.isArray(array)) {
                size = size * array.length
                array = array[0]
            }

            return size
        } catch (error) {
            throw this.process_stack_trace(error, this.constructor.name)
        }
    }
}

module.exports = new ArrayGetSizeHandler()