use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

catch

=usage

  my $catch = $self->catch($object, 'App::Exception');

=description

Returns truthy if the objects passed are of the same kind.

=signature

catch(Object $arg1, ClassName $arg2) : Int

=type

method

=cut

# TESTING

use_ok 'Data::Object::Role::Catchable';

my $data = 'Data::Object::Role::Catchable';

can_ok $data, 'catch';

ok 1 and done_testing;
