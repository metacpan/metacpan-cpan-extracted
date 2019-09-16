use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

e

=usage

  my $e = $exception->explain();

=description

Render the exception message with optional context and stack trace.

=signature

e() : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Exception';

my $e = 'Data::Object::Exception';

can_ok $e, 'explain';

ok 1 and done_testing;
