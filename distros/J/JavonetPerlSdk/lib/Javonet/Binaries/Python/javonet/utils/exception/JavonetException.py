class JavonetException(Exception):
    def __init__(self, name, message, traceback_str):
        self.name = name
        self.message = message
        self.traceback_str = traceback_str

    def __str__(self):
        return f"{self.name}: {self.message}\n{self.traceback_str}"


