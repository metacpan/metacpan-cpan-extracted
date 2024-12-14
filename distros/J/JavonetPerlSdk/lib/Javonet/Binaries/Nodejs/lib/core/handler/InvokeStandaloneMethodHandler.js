const AbstractHandler = require('./AbstractHandler')

class InvokeStandaloneMethodHandler extends AbstractHandler {
    requiredParametersCount = 2

    constructor() {
        super()
    }

    process(command) {
        try {
            if (command.payload.length < this.requiredParametersCount) {
                throw new Error('Invoke standalone Method parameters mismatch')
            }

            const { payload } = command
            const type = payload[0]
            const methodName = payload[1]
            const args = payload.slice(2)

            if (typeof type === 'function') {
                // assuming that function is exported as single (default)
                return Reflect.apply(type, undefined, args)
            }

            if (typeof type === 'object') {
                // assuming that function inside of multiple exports
                const method = type[methodName]

                if (typeof method === 'function') {
                    return Reflect.apply(method, undefined, args)
                }
                return this.throwError(type, methodName)
            } else {
                throw new Error(`Function ${methodName} not found in libary.`)
            }
        } catch (error) {
            throw this.process_stack_trace(error, this.constructor.name)
        }
    }

    throwError(type, methodName) {
        const methods = Object.getOwnPropertyNames(type).filter(
            (property) => typeof type[property] === 'function'
        )

        let message = `Function ${methodName} not found in libary. Available standalone methods:\n`
        methods.forEach((methodIter) => {
            message += `${methodIter}\n`
        })

        throw new Error(message)
    }
}

module.exports = new InvokeStandaloneMethodHandler()
