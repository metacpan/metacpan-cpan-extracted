package Lemonldap::NG::Common::Logger::Syslog;

use strict;
use Sys::Syslog qw(:standard);

our $VERSION = '2.18.0';

sub new {
    my ( $class, $conf, %args ) = @_;
    my $level = $conf->{logLevel} || 'info';
    my $self  = bless {}, $class;
    our $done;
    if ( $args{user} ) {
        $self->{facility} = $conf->{userSyslogFacility} || 'auth';
        $self->{options}  = $conf->{userSyslogOptions}  || 'cons,pid,ndelay';
    }
    else {
        $self->{facility} = $conf->{syslogFacility} || 'daemon';
        $self->{options}  = $conf->{syslogOptions}  || 'cons,pid,ndelay';
    }
    # Avoid to launch openlog multiple times, to prevent mech degradation from native to unix
    # See also https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/-/issues/2771
    unless ($done) {
        eval {
            openlog( 'LLNG', $self->{options}, $self->{facility} );
            $done = 1;
        };
    }
    no warnings 'redefine';
    my $show = 1;

    foreach (qw(error warn notice info debug)) {
        if ($show) {
            my $name = $_;
            $name = 'warning' if ( $_ eq 'warn' );
            $name = 'err'     if ( $_ eq 'error' );
            eval
              qq'sub $_ {syslog("$name|".\$_[0]->{facility},"[$_] ". \$_[1])}';
            die $@ if ($@);
        }
        else {
            eval qq'sub $_ {1}';
        }
        $show = 0 if ( $level eq $_ );
    }
    die "Unknown logLevel $level" if $show;

    return $self;
}

1;
