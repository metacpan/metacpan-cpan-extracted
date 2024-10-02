const AbstractHandler = require("./AbstractHandler")


class ArrayGetItemHandler extends AbstractHandler {
    requiredParametersCount = 2

    constructor() {
        super()
    }

    process(command) {
        try {
            if (command.payload.length < this.requiredParametersCount) {
                throw new Error("Array Get Item parameters mismatch")
            }
            let array = command.payload[0]
            let indexes
            if (Array.isArray(command.payload[1])) {
                indexes = command.payload[1]
            } else {
                indexes = command.payload.slice(1)
            }

            if (indexes.length === 1) {
                return array[indexes]
            } else {
                let array_copy = [...array]
                for (let i = 0; i < indexes.length; i++) {
                    array_copy = array_copy[indexes[i]]
                }
                return array_copy
            }
        } catch (error) {
            throw this.process_stack_trace(error, this.constructor.name)
        }
    }
}

module.exports = new ArrayGetItemHandler()