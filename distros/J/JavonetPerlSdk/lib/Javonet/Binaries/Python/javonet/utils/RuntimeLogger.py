import platform
import os
import sys


class RuntimeLogger:

    not_logged_yet = True
    @staticmethod
    def get_runtime_info():
        try:
            return (
                "Python Managed Runtime Info:\n"
                f"Python Version: {platform.python_version()}\n"
                f"Python executable path: {sys.executable}\n"
                f"Python Path: {sys.path}\n"
                f"Python Implementation: {platform.python_implementation()}\n"
                f"OS Version: {platform.system()} {platform.version()}\n"
                f"Process Architecture: {platform.machine()}\n"
                f"Current Directory: {os.getcwd()}\n"
            )
        except Exception as e:
            return "Python Managed Runtime Info: Error while fetching runtime info"

    @staticmethod
    def print_runtime_info():
        if RuntimeLogger.not_logged_yet:
            print(RuntimeLogger.get_runtime_info())
            RuntimeLogger.not_logged_yet = False
    
