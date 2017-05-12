use Test::More qw(no_plan);

BEGIN {
   eval {
      package NotMain;

      use strict;
      use warnings;
      use Test::More;
      use Log::Contextual::SimpleLogger;

      use Log::Contextual qw(:log),
        -default_logger =>
        Log::Contextual::SimpleLogger->new({levels => [qw( )]});

      eval {
         log_info { "Yep" }
      };
      is($@, '', 'Invoked log function in package other than main');
   };

   is($@, '', 'non-main package subtest did not die');
}
