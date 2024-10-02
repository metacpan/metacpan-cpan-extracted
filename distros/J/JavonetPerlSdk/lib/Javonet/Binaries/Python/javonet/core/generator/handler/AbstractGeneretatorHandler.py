
class AbstractGeneratorHandler:

    def generate_command(self, analyzed_object, parent_command, handlers):
        raise NotImplementedError('subclasses must override generate_command()!')

    def generate_code(self, existing_string_builder, common_command, used_object, handlers):
        raise NotImplementedError('subclasses must override generate_command()!')
