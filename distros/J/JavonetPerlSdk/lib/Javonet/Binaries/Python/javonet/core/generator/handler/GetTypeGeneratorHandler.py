import inspect

from javonet.core.generator.handler.AbstractGeneretatorHandler import AbstractGeneratorHandler
from javonet.core.generator.internal.SharedHandlerType import SharedHandlerType
from javonet.utils.Command import Command
from javonet.utils.CommandType import CommandType
from javonet.utils.RuntimeName import RuntimeName


class GetTypeGeneratorHandler(AbstractGeneratorHandler):
    def generate_command(self, analyzed_object, parent_command, handlers):
        get_type_command = Command(RuntimeName.python, CommandType.GetType, [])
        get_type_command = get_type_command.add_arg_to_payload(analyzed_object.__name__)
        get_type_command = get_type_command.add_arg_to_payload(
            handlers.SHARED_HANDLER[SharedHandlerType.MODIFIER].generate_command(analyzed_object.__name__,
                                                                                 get_type_command, handlers))
        clazz_variables_names = [attr for attr in analyzed_object.__dict__ if
                                 not callable(getattr(analyzed_object, attr)) and not attr.startswith("__")]
        clazz_methods = inspect.getmembers(analyzed_object, predicate=inspect.isfunction)
        clazz_constructor = getattr(analyzed_object, "__init__")

        clazz_variables_dict = dict()
        for method in clazz_methods:
            method_type = self.inspect_type(analyzed_object, method[1])
            if (method_type == 'classmethod' or method_type == 'function' or method_type == 'instancemethod') and (
                    method[0] == "__init__"):
                get_type_command = get_type_command.add_arg_to_payload(
                    handlers.GENERATOR_HANDLER[CommandType.CreateClassInstance].generate_command(
                        clazz_constructor,
                        get_type_command,
                        handlers))
            if method_type == 'staticmethod':
                get_type_command = get_type_command.add_arg_to_payload(
                    handlers.GENERATOR_HANDLER[CommandType.InvokeStaticMethod].generate_command(
                        method[1],
                        get_type_command,
                        handlers))
            if (method_type == 'classmethod' or method_type == 'function' or method_type == 'instancemethod') and (
                    method[0] != "__init__"):
                get_type_command = get_type_command.add_arg_to_payload(
                    handlers.GENERATOR_HANDLER[CommandType.InvokeInstanceMethod].generate_command(
                        method[1],
                        get_type_command,
                        handlers))

        for clazz_variable_name in clazz_variables_names:
            clazz_variables_dict[clazz_variable_name] = getattr(analyzed_object, clazz_variable_name)
        for dict_items in clazz_variables_dict.items():
            get_type_command = get_type_command.add_arg_to_payload(
                handlers.GENERATOR_HANDLER[CommandType.GetStaticField].generate_command(
                    dict_items,
                    get_type_command,
                    handlers))

        return get_type_command

    def generate_code(self, existing_string_builder, common_command, used_object, handlers):
        existing_string_builder.append("\n")
        existing_string_builder.append("from javonet.sdk import Javonet")
        existing_string_builder.append("\n")
        existing_string_builder.append("class ")
        handlers.SHARED_HANDLER[SharedHandlerType.MODIFIER].generate_code(existing_string_builder, common_command,
                                                                          used_object.get_payload()[1], handlers)
        handlers.SHARED_HANDLER[SharedHandlerType.CLASS_NAME].generate_code(existing_string_builder, common_command,
                                                                            used_object.get_payload()[0], handlers)
        existing_string_builder.append(":")
        existing_string_builder.append("\n")
        handlers.SHARED_HANDLER[SharedHandlerType.CLAZZ_INSTANCE].generate_code(existing_string_builder, common_command,
                                                                                used_object, handlers)
        existing_string_builder.append("\n")
        for i in range(2, len(used_object.get_payload())):
            handlers.GENERATOR_HANDLER[used_object.get_payload()[i].command_type].generate_code(existing_string_builder,
                                                                                                common_command,
                                                                                                used_object.get_payload()[
                                                                                                    i], handlers)
            existing_string_builder.append("\n")

    def inspect_type(self, cls, func):
        ftype = None
        if func.__name__ == func.__qualname__:
            return 'function'
        elif '.<locals>' in func.__qualname__:
            return 'function'
        ftype = cls.__dict__.get(func.__name__)
        if type(ftype) == staticmethod:
            return 'staticmethod'
        elif type(ftype) == classmethod:
            return 'classmethod'
        elif ftype.__class__.__name__ == 'function':
            return 'instancemethod'
        else:
            raise TypeError('Unknown Type %s, Please check input is method or function' % func)
