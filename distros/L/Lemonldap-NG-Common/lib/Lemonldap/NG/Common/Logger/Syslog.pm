package Lemonldap::NG::Common::Logger::Syslog;

use strict;
use Sys::Syslog qw(:standard);

our $VERSION = '2.0.15';

sub new {
    my ( $class, $conf, %args ) = @_;
    my $level = $conf->{logLevel} || 'info';
    my $self  = bless {}, $class;
    if ( $args{user} ) {
        $self->{facility} = $conf->{userSyslogFacility} || 'auth';
        $self->{options}  = $conf->{userSyslogOptions}  || 'cons,pid,ndelay';
    }
    else {
        $self->{facility} = $conf->{syslogFacility} || 'daemon';
        $self->{options}  = $conf->{syslogOptions}  || 'cons,pid,ndelay';
    }
    eval { openlog( 'LLNG', $self->{options}, $self->{facility} ) };
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
