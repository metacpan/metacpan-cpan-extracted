class AbstractHandler:
    def handle_command(self, command):
        raise NotImplementedError('subclasses must override HandleCommand()!')
