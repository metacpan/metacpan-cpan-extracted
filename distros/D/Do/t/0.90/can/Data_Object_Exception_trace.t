use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

trace

=usage

  # $exception

  my $trace = $exception->trace;
  my $trace = $exception->trace(0); # all frames
  my $trace = $exception->trace(0, 5); # five frames, no skip

=description

The trace method compiles a stack trace and returns the object. By default it
skips the first frame.

=signature

trace(Int $offset, $Int $limit) : ExceptionObject

=type

method

=cut

# TESTING

use Data::Object::Exception;

can_ok "Data::Object::Exception", "trace";

my $exception = Data::Object::Exception->new('Oops');
isa_ok $exception, 'Data::Object::Exception';

ok !$exception->{frames};

$exception = $exception->trace;
ok $exception->{frames};

ok 1 and done_testing;
