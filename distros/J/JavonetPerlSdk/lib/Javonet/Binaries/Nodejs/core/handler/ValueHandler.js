const AbstractHandler = require("./AbstractHandler")


class ValueHandler extends AbstractHandler {

    constructor() {
        super()
    }
    process(command) {
        const {payload} = command
        return payload[0]
    }
}

module.exports = new ValueHandler()