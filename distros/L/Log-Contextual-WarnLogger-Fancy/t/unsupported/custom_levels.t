
use strict;
use warnings;

use Test::More;

# Custom Levels are not presently "officially supported", mostly because
# there are concerns about their effective use and supporting them burdens us with implementation
# details that are a bit messy ( do we generate subs at AUTOLOAD or new? ... etc )
#
# So this test gives an example of how to do it, but makes no promises about its stability

use strict;
use warnings;

use Test::More;
use Log::Contextual::WarnLogger::Fancy;

my $ENV_PREFIX = 'T_LCWL';
my $GRP_PREFIX = 'T_LCWL_GROUP';

use Log::Contextual qw{:log},
  -levels => [qw( trace debug info warn fatal custom )];
use Test::Differences qw( eq_or_diff );
use Term::ANSIColor qw( colorstrip );
use lib qw[t/lib];
use KENTNL::WLTest qw( with_env );

my $t_env = with_env();
my $elip  = chr(166);

# Generate the utilty Log::Contextual will call
Log::Contextual::WarnLogger::Fancy::_gen_level('custom');

sub every_log {
    my ($logger) = @_;

    # This doesn't do anything yet.
    push @{ $logger->{levels} }, 'custom';

    # Configure the rank of level "custom"
    $logger->{level_nums}->{custom} = 20;

    # Specify how to format level 'custom''s label.
    $logger->{level_labels}->{custom} = 'custo';
    log_trace { 'trace message' };
    log_debug { 'debug message' };
    log_info { 'info message' };
    log_warn { 'warn message' };
    log_fatal { 'fatal message' };
    log_custom { 'custom message' };
}

eq_or_diff(
    colorstrip(
        with_env()->with_warner( env_prefix => $ENV_PREFIX )
          ->run( \&every_log ),
    ),
    "[warn ] warn message\n[fatal] fatal message\n[custo] custom message\n",
    "Default has warning and fatals shown but not info"
);

done_testing;

