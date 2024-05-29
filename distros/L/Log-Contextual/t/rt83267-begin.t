use strict;
use warnings;

use Test::More;

BEGIN {
  eval {
    package NotMain;
    use Log::Contextual::SimpleLogger;

    use Log::Contextual qw(:log),
      -default_logger =>
      Log::Contextual::SimpleLogger->new({levels => [qw( )]});

    eval {
      log_info { "Yep" }
    };
    ::is($@, '', 'Invoked log function in package other than main');
  };

  is($@, '', 'non-main package subtest did not die');
}

done_testing;
