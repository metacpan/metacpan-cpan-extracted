use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # Oops

  my $exception = Data::Object::Exception->new(
    message => 'Oops'
  });

=description

The new method expects a message, or named arguments, and returns a new class
instance.

=signature

new(HashRef $arg1) : ExceptionObject

=type

method

=cut

# TESTING

use Data::Object::Exception;

can_ok "Data::Object::Exception", "new";

my $exception;

# single-arg instantiate
$exception = Data::Object::Exception->new('Oops');
isa_ok $exception, 'Data::Object::Exception';
is $exception->{message}, 'Oops';

# instantiate with object
$exception = Data::Object::Exception->new({ message => 'Oops' });
isa_ok $exception, 'Data::Object::Exception';
is $exception->{message}, 'Oops';

ok 1 and done_testing;
