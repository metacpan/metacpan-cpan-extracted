const AbstractHandler = require('./AbstractHandler')

class LoadLibraryHandler extends AbstractHandler {
    requiredParametersCount = 1

    constructor() {
        super()
    }

    process(command) {
        if (command.payload.length < this.requiredParametersCount) {
            throw new Error("Load Library parameters mismatch")
        }
        let {payload} = command
        let [lib] = payload
        let pathArray = lib.split(/[/\\]/)
        let libraryName = pathArray.length > 1 ? pathArray[pathArray.length - 1] : pathArray[0]
        libraryName = libraryName.replace('.js', '')

        let moduleExports

        try {
            moduleExports = require(lib)
        } catch (error) {
            try {
                moduleExports = require(`${process.cwd()}/${lib}`)
            } catch (error) {
                throw this.process_stack_trace(error, this.constructor.name)
            }
        }
        global[libraryName] = moduleExports

        for (const [key, value] of Object.entries(moduleExports)) {
            // Here, `key` is the name of the export, and `value` is the exported type itself.
            global[key] = value
        }
        return 0
    }
}

module.exports = new LoadLibraryHandler()
