#
# Simple tests of the S-Lang library interface
#

use strict;

my $loaded = 0;
BEGIN { use Test::More tests => 5; }
END   { fail( "Able to 'use Inline SLang'" ) unless $loaded; }

## Tests

# could not work out how to use Test::More's use_ok()
# to test loading the module
#
use Inline 'SLang';
pass( "Able to 'use Inline SLang'" );
$loaded = 1;

# mainly here for users who 'perl -Mblib t/00init.t'
# this file
#
eval { print JAxH('Inline'); };
is( $@, "", "We're just another Inline hacker" );

# test the error handler
eval { Inline::SLang::sl_eval( "variable = ;" ); };
like( $@, qr/^S-Lang Error: Syntax Error: Expecting a variable name: found '=', line 1, file: \*\*\*string\*\*\*/,
	"Can catch S-Lang error messages via eval" );

# and check that the interpreter is still working
is( JAxH("re-installed"), "Just Another re-installed Hacker\n",
	"and the S-Lang interpreter has been re-started" );

# Just check that the default SETUP option is 'slsh'.
# Tests of the actual functionality of this option are in
#  01setup1.t and 01setup2.t
#
my $counter = Inline::SLang::sl_setup_called();
is ( $counter, 1, "The sl_setup_as_slsh() code has been called once." );

__END__
__SLang__

define somefunc () {}

define JAxH(x) {
  return sprintf( "Just Another %s Hacker\n", x );
}
