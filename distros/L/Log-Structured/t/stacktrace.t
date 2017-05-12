use strictures 1;
use Test::More;
use Test::Deep;

use Log::Structured;

my @var;

my $l_s = Log::Structured->new({
  log_stacktrace => 1,
  log_line => 1,
  log_subroutine => 1,
  log_package => 1,
  log_file => 1,
  log_event_listeners => [sub { push @var, $_[1] }],
});

{
   package A::Robot;
   sub lololol { $l_s->log_event({ message => 'silly' }) }
}

$l_s->log_event({ message => 'shallow' });

sub foo { bar() }
sub bar { baz() }
sub baz { biff() }
sub biff {
   $l_s->log_event({ message => 'deep' });
}

my $flags = ($] >= 5.010
  ? 7
  : 6
);

foo();

# It's silly to test line number.  subroutine is just as unique and way more
# stable
cmp_deeply( $var[0], {
   package  => __PACKAGE__,
   file     => __FILE__,
   line     => ignore(),
   subroutine => 'Log::Structured::log_event',
   stacktrace => [
      [ __PACKAGE__, __FILE__, ignore(), 'Log::Structured::log_event', ( ignore() ) x $flags],
   ],
   message  => 'shallow',
}, 'Shallow log event works');

cmp_deeply( $var[1], {
   package  => __PACKAGE__,
   file     => __FILE__,
   line     => ignore(),
   subroutine => 'Log::Structured::log_event',
   stacktrace => [
      [ __PACKAGE__, __FILE__, ignore(), 'Log::Structured::log_event', ( ignore() ) x $flags],
      [ __PACKAGE__, __FILE__, ignore(), 'main::biff', ( ignore() ) x $flags],
      [ __PACKAGE__, __FILE__, ignore(), 'main::baz', ( ignore() ) x $flags],
      [ __PACKAGE__, __FILE__, ignore(), 'main::bar', ( ignore() ) x $flags],
      [ __PACKAGE__, __FILE__, ignore(), 'main::foo', ( ignore() ) x $flags],
   ],
   message  => 'deep',
}, 'Deep log event works');

$l_s->caller_depth(3);
$l_s->log_stacktrace(undef);

foo();

cmp_deeply( $var[2], {
   package  => __PACKAGE__,
   file     => __FILE__,
   line     => ignore(),
   subroutine => 'main::bar',
   message  => 'deep',
}, 'caller_depth works');

$l_s->caller_depth(undef);
A::Robot::lololol();

cmp_deeply( $var[3], {
   package  => 'A::Robot',
   file     => __FILE__,
   line     => ignore(),
   subroutine => 'Log::Structured::log_event',
   message  => 'silly',
}, 'caller_depth works');

$l_s->caller_clan(qr/^A::Robot/);
A::Robot::lololol();

cmp_deeply( $var[4], {
   package  => __PACKAGE__,
   file     => __FILE__,
   line     => ignore(),
   subroutine => 'A::Robot::lololol',
   message  => 'silly',
}, 'caller_clan works');

# this is a dumb thing to do, but I just want to make sure that I test
# what happens when people do it
$l_s->caller_clan(qr/^A::Robot|^main/);
A::Robot::lololol();

cmp_deeply( $var[5], {
   package  => undef,
   file     => undef,
   line     => undef,
   subroutine => undef,
   message  => 'silly',
}, "We don't get in any dumb infinite loops when people ask for crazy things");

done_testing;

