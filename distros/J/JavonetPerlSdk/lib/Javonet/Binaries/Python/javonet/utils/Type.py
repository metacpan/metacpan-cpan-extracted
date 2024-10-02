from enum import Enum


class Type(Enum):
    Command = 0
    JavonetString = 1
    JavonetInteger = 2
    JavonetBoolean = 3
    JavonetFloat = 4
    JavonetByte = 5
    JavonetChar = 6
    JavonetLongLong = 7
    JavonetDouble = 8
    JavonetUnsignedLongLong = 9
    JavonetUnsignedInteger = 10
    JavonetNoneType = 11
