use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

type

=usage

  my $type = $self->type();

=description

The type method returns object type string.

=signature

type() : Str

=type

method

=cut

# TESTING

use_ok 'Data::Object::Base';

my $data = 'Data::Object::Base';

can_ok $data, 'type';

ok 1 and done_testing;
