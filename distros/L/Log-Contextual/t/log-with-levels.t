use strict;
use warnings;

use Log::Contextual qw{:dlog :log with_logger set_logger},
  -levels => ['custom'];
use Log::Contextual::SimpleLogger;
use Test::More;

my $logger = DumbLogger->new;

set_logger(sub { $logger });

log_custom { 'fiSMBoC' };
is($DumbLogger::var, "fiSMBoC", "custom works");

my @vars = log_custom { 'fiSMBoC: ' . $_[1] } qw{foo bar baz};
is($DumbLogger::var, "fiSMBoC: bar", "log_custom works with input");
ok(
  eq_array(\@vars, [qw{foo bar baz}]),
  "log_custom passes data through correctly"
);

my $val = logS_custom { 'fiSMBoC: ' . $_[0] } 'foo';
is($DumbLogger::var, "fiSMBoC: foo", "logS_custom works with input");
is($val, 'foo', "logS_custom passes data through correctly");

my @foo = Dlog_custom { "Look ma, data: $_" } qw{frew bar baz};

ok(
  eq_array(\@foo, [qw{frew bar baz}]),
  "Dlog_custom passes data through correctly"
);
is(
  $DumbLogger::var,
  qq(Look ma, data: "frew"\n"bar"\n"baz"\n),
  "Output for Dlog_custom is correct"
);

my $bar = DlogS_custom { "Look ma, data: $_" }[qw{frew bar baz}];
ok(eq_array($bar, [qw{frew bar baz}]),
  'DlogS_custom passes data through correctly');
like(
  $DumbLogger::var,
  qr(Look ma, data: \[),
  "Output for DlogS_custom is correct"
);

@foo = Dlog_custom { "nothing: $_" } ();
ok(eq_array(\@foo, []), "Dlog_custom passes nothing through correctly");
is($DumbLogger::var, "nothing: ()", "Output for Dlog_custom is correct");

ok(!main->can($_), "$_ not imported")
  for map +("log_$_", "logS_$_"), qw(debug trace warn info error fatal);

ok(!eval { Log::Contextual->import; 1 }, 'Blank Log::Contextual import dies');

BEGIN {

  package DumbLogger;

  our $var;
  sub new { bless {}, 'DumbLogger' }
  sub is_custom { 1 }
  sub custom { $var = $_[1] }

  1;
}

done_testing;
