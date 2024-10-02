from io import StringIO


class PythonStringBuilder:
    _file_str = None

    def __init__(self):
        self._file_str = StringIO()

    def append(self, string):
        self._file_str.write(string)
        return self

    def __str__(self):
        return self._file_str.getvalue()
