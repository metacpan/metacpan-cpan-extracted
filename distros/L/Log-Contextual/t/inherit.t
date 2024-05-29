use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Log::Contextual qw(set_logger);
use Log::Contextual::SimpleLogger;

BEGIN {
  package MySuperClass;
  use Log::Contextual qw(:log);
}

BEGIN {
  package MyChildClass;
  BEGIN { our @ISA = qw(MySuperClass) };
  use Log::Contextual qw(:log);

  sub do_thing {
    log_error { "child class log" };
  }
}

my $last_log;
set_logger(Log::Contextual::SimpleLogger->new({
    levels  => [qw(error)],
    coderef => sub { $last_log = shift },
}));

is exception { MyChildClass->do_thing; }, undef,
  'log imports work in child class with exports in parent';

done_testing;
