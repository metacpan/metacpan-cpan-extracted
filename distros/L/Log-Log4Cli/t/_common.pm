package _common;

# common parts for tests

use parent qw(Exporter);

our @EXPORT_OK = qw($LVL_MAP);

our $LVL_MAP = {
    FATAL  => -2,
    ERROR  => -1,
    ALERT  => -1,
    WARN   =>  0,
    INFO   =>  1,
    DEBUG  =>  2,
    TRACE  =>  3,
};

1;
