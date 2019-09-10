use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoArgs

=usage

  # given xyz

  my $self = Data::Object::Library->DoArgs(...);

=description

This function returns the type configuration for a L<Data::Object::Args>
object.

=signature

DoArgs() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoArgs";

ok 1 and done_testing;
