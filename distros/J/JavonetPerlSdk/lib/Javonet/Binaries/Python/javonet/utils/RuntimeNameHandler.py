from javonet.utils.RuntimeName import RuntimeName


class RuntimeNameHandler:

    @staticmethod
    def get_name(runtime_name):
        if isinstance(runtime_name, RuntimeName):
            if runtime_name == RuntimeName.clr:
                return "clr"
            elif runtime_name == RuntimeName.go:
                return "go"
            elif runtime_name == RuntimeName.jvm:
                return "jvm"
            elif runtime_name == RuntimeName.netcore:
                return "netcore"
            elif runtime_name == RuntimeName.perl:
                return "perl"
            elif runtime_name == RuntimeName.python:
                return "python"
            elif runtime_name == RuntimeName.ruby:
                return "ruby"
            elif runtime_name == RuntimeName.nodejs:
                return "nodejs"
        else:
            raise Exception("Invalid runtime name.")
