use strict;
use warnings;

use Log::Contextual::WarnLogger;
use Log::Contextual qw{:log set_logger} => -logger =>
  Log::Contextual::WarnLogger->new({env_prefix => 'FOO'});
use Test::More;
my $l = Log::Contextual::WarnLogger->new({env_prefix => 'BAR'});

{
  local $ENV{BAR_TRACE} = 0;
  local $ENV{BAR_DEBUG} = 1;
  local $ENV{BAR_INFO}  = 0;
  local $ENV{BAR_WARN}  = 0;
  local $ENV{BAR_ERROR} = 0;
  local $ENV{BAR_FATAL} = 0;
  ok(!$l->is_trace, 'is_trace is false on WarnLogger');
  ok($l->is_debug,  'is_debug is true on WarnLogger');
  ok(!$l->is_info,  'is_info is false on WarnLogger');
  ok(!$l->is_warn,  'is_warn is false on WarnLogger');
  ok(!$l->is_error, 'is_error is false on WarnLogger');
  ok(!$l->is_fatal, 'is_fatal is false on WarnLogger');
}

{
  local $ENV{BAR_UPTO} = 'TRACE';

  ok($l->is_trace, 'is_trace is true on WarnLogger');
  ok($l->is_debug, 'is_debug is true on WarnLogger');
  ok($l->is_info,  'is_info is true on WarnLogger');
  ok($l->is_warn,  'is_warn is true on WarnLogger');
  ok($l->is_error, 'is_error is true on WarnLogger');
  ok($l->is_fatal, 'is_fatal is true on WarnLogger');
}

{
  local $ENV{BAR_UPTO} = 'warn';

  ok(!$l->is_trace, 'is_trace is false on WarnLogger');
  ok(!$l->is_debug, 'is_debug is false on WarnLogger');
  ok(!$l->is_info,  'is_info is false on WarnLogger');
  ok($l->is_warn,   'is_warn is true on WarnLogger');
  ok($l->is_error,  'is_error is true on WarnLogger');
  ok($l->is_fatal,  'is_fatal is true on WarnLogger');
}

{
  local $ENV{FOO_TRACE} = 0;
  local $ENV{FOO_DEBUG} = 1;
  local $ENV{FOO_INFO}  = 0;
  local $ENV{FOO_WARN}  = 0;
  local $ENV{FOO_ERROR} = 0;
  local $ENV{FOO_FATAL} = 0;
  ok(
    eval {
      log_trace { die 'this should live' };
      1
    },
    'trace does not get called'
  );
  ok(
    !eval {
      log_debug { die 'this should die' };
      1
    },
    'debug gets called'
  );
  ok(
    eval {
      log_info { die 'this should live' };
      1
    },
    'info does not get called'
  );
  ok(
    eval {
      log_warn { die 'this should live' };
      1
    },
    'warn does not get called'
  );
  ok(
    eval {
      log_error { die 'this should live' };
      1
    },
    'error does not get called'
  );
  ok(
    eval {
      log_fatal { die 'this should live' };
      1
    },
    'fatal does not get called'
  );
}

{
  local $ENV{FOO_TRACE} = 1;
  local $ENV{FOO_DEBUG} = 1;
  local $ENV{FOO_INFO}  = 1;
  local $ENV{FOO_WARN}  = 1;
  local $ENV{FOO_ERROR} = 1;
  local $ENV{FOO_FATAL} = 1;
  my $cap;
  local $SIG{__WARN__} = sub { $cap = shift };

  log_debug { 'frew' };
  is($cap, "[debug] frew\n", 'WarnLogger outputs to STDERR correctly');
  log_trace { 'trace' };
  is($cap, "[trace] trace\n", 'trace renders correctly');
  log_debug { 'debug' };
  is($cap, "[debug] debug\n", 'debug renders correctly');
  log_info { 'info' };
  is($cap, "[info] info\n", 'info renders correctly');
  log_warn { 'warn' };
  is($cap, "[warn] warn\n", 'warn renders correctly');
  log_error { 'error' };
  is($cap, "[error] error\n", 'error renders correctly');
  log_fatal { 'fatal' };
  is($cap, "[fatal] fatal\n", 'fatal renders correctly');

}

done_testing;
