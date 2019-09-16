use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

result

=usage

  my $result = $try->result(@args);

=description

The result method executes the try/catch/default/finally logic and returns
either 1) the return value from the successfully tried operation 2) the return
value from the successfully matched catch condition if an exception was thrown
3) the return value from the default catch condition if an exception was thrown
and no catch condition matched. When invoked, the C<try> and C<finally>
callbacks will received an C<invocant> if one was provided to the constructor,
the default C<arguments> if any were provided to the constructor, and whatever
arguments were passed directly to this method.

=signature

result(Any @args) : Any

=type

method

=cut

# TESTING

use Data::Object::Try;

can_ok "Data::Object::Try", "result";

{
  package Event;

  use Moo;

  sub dieself {
    die shift;
  }

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
my $result;
my $run = 0;

$event = Event->new;
$try = Data::Object::Try->new(invocant => $event);
$try->call('request');
$try->catch('ARRAY', sub{['caught', @_]});
$try->finally(sub{$run++});

$result = $try->result(1);

is $run, 1;
is_deeply $result, ['caught', ['oops']];

$try->no_catch;
$try->catch('ARRAY', 'failure');

$result = $try->result(1);

is $run, 2;
is_deeply $result, ['logged', ['oops']];

$try->no_catch;
$try->default('failure');

$result = $try->result(1);

is $run, 3;
is_deeply $result, ['logged', ['oops']];

$try->no_catch;
$try->no_default;
$try->no_finally;
$try->call('dieself');

$try->catch('ARRAY', sub{['isa_array', @_]});
$try->catch('Event', sub{['isa_event', @_]});

$result = $try->result(1);

is $run, 3;
is_deeply $result, ['isa_event', $event];

ok 1 and done_testing;
