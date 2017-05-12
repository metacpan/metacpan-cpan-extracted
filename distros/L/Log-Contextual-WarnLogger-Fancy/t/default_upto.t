
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

my $t_env = with_env();
my $elip  = chr(166);

sub every_log {
    log_trace { 'trace message' };
    log_debug { 'debug message' };
    log_info { 'info message' };
    log_warn { 'warn message' };
    log_fatal { 'fatal message' };
}
eq_or_diff(
    colorstrip(
        with_env()->with_warner( env_prefix => $ENV_PREFIX )
          ->run( \&every_log ),
    ),
    "[warn ] warn message\n[fatal] fatal message\n",
    "Default has warning and fatals shown but not info"
);

eq_or_diff(
    colorstrip(
        with_env()
          ->with_warner( env_prefix => $ENV_PREFIX, default_upto => 'debug' )
          ->run( \&every_log ),
    ),
    "[debug] debug message\n[info ] info message\n"
      . "[warn ] warn message\n[fatal] fatal message\n",
    "Raising the default up-to level shows more warnings"
);

eq_or_diff(
    colorstrip(
        with_env( UPTO => 'info' )->with_warner( env_prefix => $ENV_PREFIX, )
          ->run( \&every_log )
    ),
    "[info ] info message\n[warn ] warn message\n[fatal] fatal message\n",
    "ENV UPTO raises upto"
);

eq_or_diff(
    colorstrip(
        with_env( GUPTO => 'info' )->with_warner(
            env_prefix       => $ENV_PREFIX,
            group_env_prefix => $GRP_PREFIX,
        )->run( \&every_log )
    ),
    "[info ] info message\n[warn ] warn message\n[fatal] fatal message\n",
    "ENV Group UPTO raises upto"
);

done_testing;
