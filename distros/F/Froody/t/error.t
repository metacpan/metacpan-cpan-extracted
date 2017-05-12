#!perl

#############################################################################
# Basic tests for the Froody::Error class - it throws properly, it stringifies
# properly, we keep the data sections, etc.
#
# seperate tests isa_err.t checks that 'inheritence' works and 'meta_err.t'
# checks thet all errors Froody throw are good.
#############################################################################

use warnings;
use strict;

use Test::More tests => 18;
use Test::Exception;

use Froody::Error qw(err);

# check that an empty error handles right:
dies_ok { Froody::Error->throw("") } "error thrown";
is( $@->code, "unknown", "code is unknown");
like( $@, qr/^\Qunknown\E\n.../, "stringifies ok");

# check that an error code works right
dies_ok { Froody::Error->throw("pie.cold") } "error thrown";
is( $@->code, "pie.cold", "code is pie.cold");
like( $@, qr/^\Qpie.cold\E\n.../, "stringifies ok");

# check the message works right
dies_ok { Froody::Error->throw("pie.cold", "My PIE is cold!", { pie => 'cold' }) } "error thrown";
is( $@->code, "pie.cold", "code is pie.cold");
is( $@->message, "My PIE is cold!", "body is hello");
is( $@->msg, "My PIE is cold!", "body is hello");
is( $@->text, "My PIE is cold!", "body is hello");
is_deeply( $@->data, { pie => 'cold' }, "Pie is definitely cold.");
like( $@, qr/^pie\.cold - My PIE is cold!.*Data:.*---.*pie: cold.*Stack trace:.*/s, "stringifies ok");

ok $@->isa_err('pie.cold'), 'specific error';
ok $@->isa_err('pie'), 'generic class of error';

is err("pie.cold"), 1, 'error has occurred';
is err("pie"), 1, 'more generic catch of error';

$@ = undef;
is err("pie.cold"), undef, 'no error now';
