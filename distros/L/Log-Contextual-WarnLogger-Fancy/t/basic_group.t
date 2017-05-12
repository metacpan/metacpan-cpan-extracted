
use strict;
use warnings;

use Test::More;
use Log::Contextual::WarnLogger::Fancy;

my $ENV_PREFIX = 'T_LCWL';
my $GRP_PREFIX = 'T_LCWL_GROUP';

use Log::Contextual qw{:log};
use Test::Differences qw( eq_or_diff );
use Term::ANSIColor qw( colorstrip );
use lib qw[t/lib];
use KENTNL::WLTest qw( with_env );

my $t_env = with_env( GINFO => 1, GDEBUG => 1 );
my $elip = chr(166);

eq_or_diff(
    colorstrip(
        $t_env->with_warner(
            env_prefix       => $ENV_PREFIX,
            group_env_prefix => [ $GRP_PREFIX, 'T' ],
          )->run(
            sub {
                log_info { 'info message' };
                log_debug { 'debug message' };
            },
          )
    ),
    "[info ] info message\n" . "[debug] debug message\n",
    "Basic group controls work",
);

done_testing;

