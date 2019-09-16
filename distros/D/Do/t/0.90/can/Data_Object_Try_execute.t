use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

execute

=usage

  my $result = $try->execute($callback, @args);

=description

The execute method takes a coderef and executes it with any given arguments.
When invoked, the callback will received an C<invocant> if one was provided to
the constructor, the default C<arguments> if any were provided to the
constructor, and whatever arguments were passed directly to this method.

=signature

execute(CodeRef $callback, Any @args) : Any

=type

method

=cut

# TESTING

use Data::Object::Try;

can_ok "Data::Object::Try", "execute";

{
  package Event;

  use Moo;

  sub request {
    die ['oops'];
  }

  sub failure {
    return ['logged', @_];
  }

  1;
}

my $try;
my $callback;
my $event;

$event = Event->new;
$try = Data::Object::Try->new(invocant => $event);
is_deeply $try->execute(sub{['always', @_]},1,2,3), ['always', $event, 1..3];

ok 1 and done_testing;
