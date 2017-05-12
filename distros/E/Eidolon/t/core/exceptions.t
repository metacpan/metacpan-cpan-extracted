#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/core/exceptions.t - exceptions tests
#
# ==============================================================================  

use Test::More tests => 16;
use warnings;
use strict;

# ------------------------------------------------------------------------------
# BEGIN()
# test initialization
# ------------------------------------------------------------------------------
BEGIN
{
    use_ok("Eidolon::Core::Exception");
    use_ok("Eidolon::Core::Exception::Builder");
    use_ok("Eidolon::Core::Exceptions");
}

# methods
ok( Eidolon::Core::Exception->can("throw"),          "throw method"          );
ok( Eidolon::Core::Exception->can("rethrow"),        "rethrow method"        );
ok( Eidolon::Core::Exception->can("overloaded_equ"), "overloaded_equ method" );
ok( Eidolon::Core::Exception->can("overloaded_str"), "overloaded_str method" );

eval
{
    # will die
    throw Eidolon::Core::Exception("test 0123456789");
};

# generic exception tests
ok( $@,                                "exception throw"       );
ok( $@ eq "Eidolon::Core::Exception",  "exception type"        );
is( $@->line,    35,                   "exception line number" );
is( $@->message, "test 0123456789",    "exception message"     );

like( $@->file,  qr/exceptions\.t$/,   "file name"             );
like( "$@",      qr/^Base exception/,  "exception string"      );

eval
{
    # will die here too
    throw CoreError::Compile;
};

# core exception tests
ok( $@,                               "core exception"         );
ok( $@ eq "CoreError::Compile",       "core exception type"    );
ok( $@ eq "Eidolon::Core::Exception", "exception inheritance"  );

