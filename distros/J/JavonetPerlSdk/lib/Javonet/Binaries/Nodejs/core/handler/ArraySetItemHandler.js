const AbstractHandler = require("./AbstractHandler")


class ArraySetItemHandler extends AbstractHandler {
    requiredParametersCount = 3

    constructor() {
        super()
    }

    process(command) {
        try {
            if (command.payload.length < this.requiredParametersCount) {
                throw new Error("Array Set Item parameters mismatch")
            }

            let array = command.payload[0]
            let value = command.payload[2]
            let indexes
            if (Array.isArray(command.payload[1])) {
                indexes = command.payload[1]
            } else {
                indexes = [command.payload[1]]
            }

            if (indexes.length === 1) {
                // one-dimensional array
                array[indexes] = value
            } else {
                // multi-dimensional array
                for (let i = 0; i < indexes.length - 1; i++) {
                    array = array[indexes[i]]
                }
                array[indexes[indexes.length - 1]] = value
            }

            return 0;
        } catch (error) {
            throw this.process_stack_trace(error, this.constructor.name)
        }
    }
}

module.exports = new ArraySetItemHandler()