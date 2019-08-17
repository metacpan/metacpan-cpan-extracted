use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

schema

=usage

  my $schema = $self->schema($name);

=description

Returns a new Schema object.

=signature

schema(Str $name, Any %args) : Schema

=type

method

=cut

# TESTING

use Doodle;

can_ok "Doodle", "schema";

my $d = Doodle->new;
my $s = $d->schema('webapp');

isa_ok $s, 'Doodle::Schema';
is $s->name, 'webapp';

ok 1 and done_testing;
