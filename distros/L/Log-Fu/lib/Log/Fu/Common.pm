package Log::Fu::Common;
use strict;
use warnings;
use base qw(Exporter);
#Simple common levels

our (@EXPORT,%EXPORT_TAGS,@EXPORT_OK);
use Constant::Generate [qw(
    LOG_DEBUG
    LOG_INFO
    LOG_WARN
    LOG_ERR
    LOG_CRIT
)], -export_ok => 1,
    -tag => 'levels',
    -mapname => 'strlevel',
    -export_tags => 1;

sub LEVELS() { qw(debug info warn err crit) }
my @_syslog_levels = qw(DEBUG INFO WARNING ERR CRIT);
sub syslog_level { $_syslog_levels[$_[0]] }
push @EXPORT, qw(syslog_level LEVELS);

our %Config;

push @EXPORT_OK, '%Config';
my @ansi_terms = qw(
    xterm
    xterm-color
    rxvt
    urxvt
    mlterm
    gnome-terminal
    konsole
    screen
    tmux
    v100
    linux
    ansi
    cygwin
);

sub fu_term_is_ansi {
    if(defined $ENV{TERM}) {
        foreach my $term (@ansi_terms) {
            return 1 if (index($ENV{TERM}, $term) >= 0)
        }
    }
    return 0;
}

push @EXPORT, 'fu_term_is_ansi';

