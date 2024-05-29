use strict;
use warnings;

use Log::Contextual::SimpleLogger;
use Test::More;
use Log::Contextual qw(:log set_logger);

my ($var1, $var2, $var3);
my $complex_dispatcher = do {

  my $l1 = Log::Contextual::SimpleLogger->new({
    levels  => [qw(trace debug info warn error fatal)],
    coderef => sub { $var1 = shift },
  });

  my $l2 = Log::Contextual::SimpleLogger->new({
    levels  => [qw(trace debug info warn error fatal)],
    coderef => sub { $var2 = shift },
  });

  my $l3 = Log::Contextual::SimpleLogger->new({
    levels  => [qw(trace debug info warn error fatal)],
    coderef => sub { $var3 = shift },
  });

  my %registry = (
    -logger => $l3,
    A1      => {
      -logger => $l1,
      lol     => $l2,
    },
    A2 => {-logger => $l2},
  );

  sub {
    my ($package, $info) = @_;

    my $logger = $registry{'-logger'};
    if (my $r = $registry{$package}) {
      $logger = $r->{'-logger'} if $r->{'-logger'};
      my (undef, undef, undef, $sub) = caller($info->{caller_level} + 1);
      $sub =~ s/^\Q$package\E:://g;
      $logger = $r->{$sub} if $r->{$sub};
    }
    return $logger;
  };
};

set_logger $complex_dispatcher;

log_debug { '1.var3' };

is($var3, "[debug] 1.var3\n", "default logger works");

$var3 = '';

A1::lol();
A1::rofl();

is($var2, "[debug] 1.var2\n", "default package logger works");
is($var1, "[debug] 1.var1\n", "package::sub logger works");

$var1 = '';
$var2 = '';

A2::foo();

is($var2, "[debug] 2.var2\n", "only default package logger works");

$var2 = '';

A3::squint();

is($var3, "[debug] 2.var3\n", "global default logger works");

BEGIN {

  package A1;
  use Log::Contextual ':log';

  sub lol {
    log_debug { '1.var2' }
  }

  sub rofl {
    log_debug { '1.var1' }
  }

  package A2;
  use Log::Contextual ':log';

  sub foo {
    log_debug { '2.var2' }
  }

  package A3;
  use Log::Contextual ':log';

  sub squint {
    log_debug { '2.var3' }
  }
}

done_testing;
