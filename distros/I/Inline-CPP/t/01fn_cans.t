use strict;
use warnings;
use Test::More tests => 1;

require Inline::CPP;

# Just a simple check that all of Inline::CPP's functions are available.
# A pretty minimal safeguard.  Ultimately I'd like to write tests for each
# of the functions, but that's lower priority for now.

can_ok( 'Inline::CPP', qw/
    call_or_instantiate     check_type      const_cast
    get_parser              info            make_enum
    register                typeconv        validate
    wrap                    write_typemap   xs_bindings
    xs_generate
/ );

done_testing();
