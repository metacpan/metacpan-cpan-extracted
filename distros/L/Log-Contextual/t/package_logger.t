use strict;
use warnings;

use Log::Contextual qw{:log with_logger set_logger};
use Log::Contextual::SimpleLogger;
use Test::More;
my $var1;
my $var2;
my $var3;
my $var_logger1 = Log::Contextual::SimpleLogger->new({
  levels  => [qw(trace debug info warn error fatal)],
  coderef => sub { $var1 = shift },
});
my $var_logger2;

BEGIN {
  $var_logger2 = Log::Contextual::SimpleLogger->new({
    levels  => [qw(trace debug info warn error fatal)],
    coderef => sub { $var2 = shift },
  })
}

my $var_logger3;

BEGIN {
  $var_logger3 = Log::Contextual::SimpleLogger->new({
    levels  => [qw(trace debug info warn error fatal)],
    coderef => sub { $var3 = shift },
  })
}

{

  package J;
  use Log::Contextual qw{:dlog :log with_logger set_logger},
    -package_logger => $var_logger3;

  sub foo {
    log_debug { 'bar' };
  }

  sub bar {
    Dlog_debug { "bar: $_" } 'frew';
  }
}

{

  package K;
  use Log::Contextual qw{:log with_logger set_logger},
    -package_logger => $var_logger2;

  sub foo {
    log_debug { 'foo' };
  }
}
J::foo;
K::foo;

is($var2, "[debug] foo\n", 'package_logger works for one package');
is($var3, "[debug] bar\n", 'package_logger works for both packages');
J::bar;
is($var3, qq([debug] bar: "frew"\n), 'package_logger works for one package');
$var2 = '';
$var1 = '';
set_logger($var_logger1);

K::foo;
is($var1, q(),             '... and set_logger does not win');
is($var2, "[debug] foo\n", '... and package_logger still gets the value');

done_testing;
