import importlib
import importlib.util
import inspect
import os
from os import listdir
from os.path import isfile, join

from javonet.core.generator.handler.Handlers import Handlers
from javonet.core.generator.internal.PythonStringBuilder import PythonStringBuilder
from javonet.utils.Command import Command
from javonet.utils.CommandType import CommandType
from javonet.utils.RuntimeName import RuntimeName


class GeneratorHandler:

    def analyze(self, package_path):
        handlers = Handlers()
        handlers.types_to_analyze.extend(self.return_classes_from_package(package_path))
        structured_command_for_class = Command(RuntimeName.python, CommandType.GenerateLib, [])

        while len(handlers.types_to_analyze) > 0:
            structured_command_for_class = structured_command_for_class. \
                add_arg_to_payload(handlers.GENERATOR_HANDLER[CommandType.GetType].
                                   generate_command(handlers.types_to_analyze.pop(0), structured_command_for_class,
                                                    handlers))

        return structured_command_for_class

    def generate(self, command, file_path):
        generator_handlers = Handlers()
        for i in range(0, len(command.get_payload())):
            existing_string_builder = PythonStringBuilder()
            if isinstance(command.get_payload()[i], Command):
                generator_handlers.GENERATOR_HANDLER[command.get_payload()[i].command_type].generate_code(
                    existing_string_builder, command, command.get_payload()[i], generator_handlers)
                self.generate_class_file(existing_string_builder, str(command.get_payload()[i].get_payload()[0]),
                                         file_path)
            else:
                raise Exception(
                    "GeneratorHandlerException: Argument is not type of PythonCommand GetTypeCommand: " + str(
                        command.getPayload()[i]))

    def generate_class_file(self, existing_string_builder, class_file_name, file_path):
        if not os.path.exists(file_path):
            os.makedirs(file_path)
        f = open(os.path.join(file_path, class_file_name) + ".py", "w+")
        f.write(str(existing_string_builder))
        f.close()

    def return_classes_from_package(self, package_path):

        onlyfiles = [f for f in listdir(package_path) if
                     isfile(join(package_path, f))]
        classes = []

        for x in onlyfiles:
            spec = importlib.util.spec_from_file_location(x[:-3], os.path.join(package_path, x))
            foo = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(foo)
            for name, obj in inspect.getmembers(foo):
                if inspect.isclass(obj):
                    classes.append(obj)

        return classes
