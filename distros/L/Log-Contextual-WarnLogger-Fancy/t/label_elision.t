
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

my $t_env = with_env( INFO => 1, DEBUG => 1 );
my $elip = chr(166);

eq_or_diff(
    colorstrip(
        $t_env->with_warner(
            env_prefix   => $ENV_PREFIX,
            label        => 'Short',
            label_length => 16
          )->run(
            sub {
                log_info { 'info message' };
                log_debug { 'debug message' };
            }
          )
    ),
    "[info             Short] info message\n"
      . "[debug            Short] debug message\n",
    "Labels under length limit padded to 16 characters works"
);

eq_or_diff(
    colorstrip(
        $t_env->with_warner(
            env_prefix   => $ENV_PREFIX,
            label        => 'This::Is::Also::Quite::Long',
            label_length => 16
          )->run(
            sub {
                log_info { 'info message' };
                log_debug { 'debug message' };
            }
          )
    ),
    "[info  This::I${elip}te::Long] info message\n"
      . "[debug This::I${elip}te::Long] debug message\n",
    "Label elision to 16 characters works"
);
eq_or_diff(
    colorstrip(
        $t_env->with_warner(
            env_prefix   => $ENV_PREFIX,
            label_length => '15',
            label        => 'This::Is::Also::Quite::Long'
          )->run(
            sub {
                log_info { 'info message' };
                log_debug { 'debug message' };
            }
          )
    ),
    "[info  This::I${elip}e::Long] info message\n"
      . "[debug This::I${elip}e::Long] debug message\n",

    "Label elision to 15 characters works",
);
eq_or_diff(
    colorstrip(
        $t_env->with_warner(
            env_prefix   => $ENV_PREFIX,
            label_length => '14',
            label        => 'This::Is::Also::Quite::Long'
          )->run(
            sub {
                log_info { 'info message' };
                log_debug { 'debug message' };
            }
          )
    ),
    "[info  This::${elip}e::Long] info message\n"
      . "[debug This::${elip}e::Long] debug message\n",

    "Label elision to 14 characters works",
);

eq_or_diff(
    colorstrip(
        $t_env->with_warner(
            env_prefix   => $ENV_PREFIX,
            label_length => '3',
            label        => 'This::Is::Also::Quite::Long'
          )->run(
            sub {
                log_info { 'info message' };
                log_debug { 'debug message' };
            }
          )
    ),
    "[info  T${elip}g] info message\n" . "[debug T${elip}g] debug message\n",

    "Label elision to 3 characters works",
);

eq_or_diff(
    colorstrip(
        $t_env->with_warner(
            env_prefix   => $ENV_PREFIX,
            label_length => '0',
            label        => 'This::Is::Also::Quite::Long'
          )->run(
            sub {
                log_info { 'info message' };
                log_debug { 'debug message' };
            }
          )
    ),
    "[info ] info message\n" . "[debug] debug message\n",

    "Label elision to 0 characters works",
);
eq_or_diff(
    colorstrip(
        $t_env->with_warner(
            env_prefix   => $ENV_PREFIX,
            label_length => 1,
            label        => 'This::Is::Also::Quite::Long',
          )->run(
            sub {
                log_info { 'info message' };
                log_debug { 'debug message' };
            }
          )
    ),
    "[info ] info message\n" . "[debug] debug message\n",

    "Label elision to 1 characters works",
);
eq_or_diff(
    colorstrip(
        $t_env->with_warner(
            env_prefix   => $ENV_PREFIX,
            label_length => 2,
            label        => 'This::Is::Also::Quite::Long'
          )->run(
            sub {
                log_info { 'info message' };
                log_debug { 'debug message' };
            }
          )
    ),
    "[info  ${elip}g] info message\n" . "[debug ${elip}g] debug message\n",

    "Label elision to 2 characters works",
);

done_testing;
