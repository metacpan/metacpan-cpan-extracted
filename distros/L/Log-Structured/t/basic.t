use strictures 1;
use Test::More;
use Test::Deep;
use Test::Fatal;

use Log::Structured;

my $var;

my $l_s = Log::Structured->new({
  category => 'CORE',
  priority => 'DEBUG',
  log_line       => 1,
  log_file       => 1,
  log_package    => 1,
  log_subroutine => 1,
  log_category   => 1,
  log_priority   => 1,
});

$l_s->add_log_event_listener(sub { $var = $_[1] });

like exception { $l_s->add_log_event_listener(1) },
   qr/^log_event_listener must be a coderef!/,
   'add_log_event_listener is validated correctly';

like exception { $l_s->add_log_event_listener([]) },
   qr/^log_event_listener must be a coderef!/,
   'add_log_event_listener is validated correctly';

ok !exception { Log::Structured->new({ log_event_listeners => [sub {}] }) },
   'log_event_listener passes through correctly';

like exception { Log::Structured->new({ log_event_listeners => [sub {},1] }) },
   qr/each log_event_listener must be a coderef!/,
   'log_event_listener is validated correctly';

$l_s->log_event({
   message => 'frew',
});

cmp_deeply( $var, {
   line     => __LINE__ - 5,
   package  => __PACKAGE__,
   subroutine => 'Log::Structured::log_event',
   category => 'CORE',
   priority => 'DEBUG',
   message  => 'frew',
   file     => __FILE__,
}, 'simple log event works');

$l_s->log_event({
   message => 'frew',
   category => 'frew',
});

cmp_deeply( $var, {
   line     => __LINE__ - 6,
   package  => __PACKAGE__,
   subroutine => 'Log::Structured::log_event',
   category => 'frew',
   priority => 'DEBUG',
   message  => 'frew',
   file     => __FILE__,
}, 'overriding category works');

{
  my $v;
  my $more_stuff = Log::Structured->new({
    log_milliseconds_since_start => 1,
    log_milliseconds_since_last_log => 1,
    log_date => 1,
    log_host => 1,
    log_pid => 1,
    log_event_listeners => [ sub { $v = $_[1] } ],
  });

  $more_stuff->log_event({ message => 'frew' });

  cmp_deeply( $v, {
    date => [(ignore()) x 9],
    host => ignore(),
    message => 'frew',
    milliseconds_since_start => ignore(),
    milliseconds_since_last_log => ignore(),
    pid => $$,
  }, 'All extra keys are logged');
}

done_testing;
