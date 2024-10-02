class AbstractGeneratorHandler {

    generate_command(analyzed_object, parent_command, handlers) {
        throw NotImplementedError('subclasses must override generate_command()!')
    }

    generate_code(existing_string_builder, common_command, used_object, handlers) {
        throw NotImplementedError('subclasses must override generate_command()!')
    }
}

module.exports = AbstractGeneratorHandler
