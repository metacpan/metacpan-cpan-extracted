use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data

=usage

  my $data = $exception->data();

=description

Render the exception message with optional context and stack trace.

=signature

data() : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Exception';

my $data = 'Data::Object::Exception';

can_ok $data, 'data';

ok 1 and done_testing;
