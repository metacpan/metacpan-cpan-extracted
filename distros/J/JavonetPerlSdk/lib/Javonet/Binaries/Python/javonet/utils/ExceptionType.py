from enum import Enum


class ExceptionType(Enum):
    Exception = 0
    IOException = 1
    FileNotFoundException = 2
    RuntimeException = 3
    ArithemticException = 4
    IllegalArgumentException = 5
    IndexOutOfBoundsException = 6
    NullPointerException = 7
    ZeroDivisionException = 8

    @staticmethod
    def to_enum(exception_name):
        if exception_name == "Exception":
            return ExceptionType.Exception.value
        if exception_name == "IOError":
            return ExceptionType.IOException.value
        if exception_name == "FileNotFoundError":
            return ExceptionType.FileNotFoundException.value
        if exception_name == "RuntimeError":
            return ExceptionType.RuntimeException.value
        if exception_name == "ArithmeticError":
            return ExceptionType.ArithemticException.value
        if exception_name == "IndexError":
            return ExceptionType.IndexOutOfBoundsException.value
        if exception_name == "AttributeError":
            return ExceptionType.NullPointerException.value
        if exception_name == "ZeroDivisionError":
            return ExceptionType.ZeroDivisionException.value
        else:
            return ExceptionType.Exception.value

    @staticmethod
    def to_exception(exception_enum):
        if exception_enum == ExceptionType.Exception.value:
            return Exception
        if exception_enum == ExceptionType.IOException.value:
            return IOError
        if exception_enum == ExceptionType.FileNotFoundException.value:
            return FileNotFoundError
        if exception_enum == ExceptionType.RuntimeException.value:
            return RuntimeError
        if exception_enum == ExceptionType.ArithemticException.value:
            return ArithmeticError
        if exception_enum == ExceptionType.IndexOutOfBoundsException.value:
            return IndexError
        if exception_enum == ExceptionType.NullPointerException.value:
            return AttributeError
        if exception_enum == ExceptionType.ZeroDivisionException.value:
            return ZeroDivisionError
        else:
            return Exception
