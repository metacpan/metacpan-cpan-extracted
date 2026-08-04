use strict;
use warnings;
use Test::More;
use JSON::Schema::Fast;

# JSON type bitmask (must match include/jsf_types.h)
use constant {
    NUL  => 1,
    OBJ  => 2,
    ARR  => 4,
    STR  => 8,
    NUM  => 16,
    INT  => 32,
    BOOL => 64,
};

sub cls { JSON::Schema::Fast::_classify($_[0]) }

my $int = 42;   $int += 0;      # force pure IV
my $num = 1.5;                  # pure NV, non-integral
my $str = "hello";
my $numstr = "5";               # numeric-looking STRING (no DWIM)

is(cls(undef),   NUL,        'undef -> null');
is(cls({}),      OBJ,        'hashref -> object');
is(cls([]),      ARR,        'arrayref -> array');
is(cls($str),    STR,        'string -> string');
is(cls($numstr), STR,        'numeric string stays string (types follow JSON, not Perl DWIM)');
is(cls($num),    NUM,        'non-integral number -> number');
is(cls($int),    NUM | INT,  'integer -> number + integer');

# boolean: a JSON decoder produces a blessed boolean object
SKIP: {
    skip 'File::Raw::JSON not available', 2
        unless eval { require File::Raw::JSON; 1 };
    my $d = File::Raw::JSON::file_json_decode('{"t":true,"f":false}');
    is(cls($d->{t}), BOOL, 'JSON true -> boolean');
    is(cls($d->{f}), BOOL, 'JSON false -> boolean');
}

done_testing;
