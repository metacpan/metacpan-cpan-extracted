use strict;
use warnings;

use Log::Contextual::SimpleLogger;
use Test::More;
use Log::Contextual qw(:log set_logger);
my $var;
my @caller_info;
my $var_log = Log::Contextual::SimpleLogger->new({
  levels  => [qw(trace debug info warn error fatal)],
  coderef => sub {
    chomp($_[0]);
    $var = "$_[0] at $caller_info[1] line $caller_info[2].\n"
  }
});
my $warn_faker = sub {
  my ($package, $args) = @_;
  @caller_info = caller($args->{caller_level});
  $var_log
};
set_logger($warn_faker);

log_debug { 'test log_debug' };
is($var,
  "[debug] test log_debug at " . __FILE__ . " line " . (__LINE__- 2) . ".\n",
  'fake warn',
);

logS_debug { 'test logS_debug' };
is(
  $var,
  "[debug] test logS_debug at " . __FILE__ . " line " . (__LINE__- 3) . ".\n",
  'fake warn'
);

logS_debug { 'test Dlog_debug' };
is(
  $var,
  "[debug] test Dlog_debug at " . __FILE__ . " line " . (__LINE__- 3) . ".\n",
  'fake warn'
);

logS_debug { 'test DlogS_debug' };
is(
  $var,
  "[debug] test DlogS_debug at " . __FILE__ . " line " . (__LINE__- 3) . ".\n",
  'fake warn'
);

done_testing;
