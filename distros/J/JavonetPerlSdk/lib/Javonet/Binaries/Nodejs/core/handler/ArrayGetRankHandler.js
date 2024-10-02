const AbstractHandler = require("./AbstractHandler")


class ArrayGetRankHandler extends AbstractHandler {

    requiredParametersCount = 1

    constructor() {
        super()
    }
    process(command) {
        try {
            if (command.payload.length < this.requiredParametersCount) {
                throw new Error("Array Get Rank parameters mismatch")
            }
            let array = command.payload[0]
            let rank = 0
            while(Array.isArray(array)) {
                rank = rank +1
                array = array[0]
            }

            return rank
        } catch (error) {
            throw this.process_stack_trace(error, this.constructor.name)
        }
    }
}

module.exports = new ArrayGetRankHandler()