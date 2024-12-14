const { Command } = require('../../..')

class AbstractHandler {
    handlers = []

    constructor() {
        if (new.target === AbstractHandler) throw new TypeError('You cannot instantiate abstract class')
    }

    // eslint-disable-next-line no-unused-vars
    process(command) {
        throw new Error('process must be implemented')
    }

    handleCommand(command) {
        this.iterate(command)
        return this.process(command)
    }

    iterate(cmd) {
        for (let i = 0; i < cmd.payload.length; i++) {
            if (cmd.payload[i] instanceof Command) {
                let inner = cmd.payload[i]
                cmd.payload[i] = this.handlers[inner.commandType].handleCommand(inner)
            }
        }
    }

    process_stack_trace(error, class_name) {
        let stackTraceArray = error.stack.split('\n').map((frame) => frame.trim())
        stackTraceArray.forEach((str, index) => {
            if (str.includes(class_name)) {
                stackTraceArray = stackTraceArray.slice(0, index).filter((s) => !s.includes(class_name))
            }
        })
        error.stack = stackTraceArray.join(' \n ')
        return error
    }
}

module.exports = AbstractHandler
