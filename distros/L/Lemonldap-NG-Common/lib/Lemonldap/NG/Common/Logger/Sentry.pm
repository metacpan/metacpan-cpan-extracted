# EXPERIMENTAL LOGGER
#
# To use it:
#  - set logger to Lemonldap::NG::Common::Logger::Sentry
#  - set sentryDsn in lemonldap-ng.ini
#  - use a high value for logLevel (or userLogger):error or warn, else too
#    many issues will be created and service will reject requests
package Lemonldap::NG::Common::Logger::Sentry;

use strict;
use Sentry::Raven;

our $VERSION = '2.0.15';

sub new {
    my $self   = bless {}, shift;
    my ($conf) = @_;
    my $show   = 1;
    $self->{raven} = Sentry::Raven->new( sentry_dsn => $conf->{sentryDsn} );

    foreach (qw(error warn notice info debug)) {
        my $rl = $_;
        $rl = 'warning' if ( $rl = 'warn' );
        $rl = 'info'    if ( $rl = 'notice' );
        if ($show) {
            eval
qq'sub $_ {\$_[0]->{raven}->capture_message(\$_[1],level => "$rl")}';
            die $@ if ($@);
        }
        else {
            eval qq'sub $_ {1}';
        }
        $show = 0 if ( $conf->{logLevel} eq $_ );
    }
    die "Unknown logLevel $conf->{logLevel}" if $show;

    return $self;
}

1;
