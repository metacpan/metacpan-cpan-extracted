package Haineko::Log;
use strict;
use warnings;

use Sys::Syslog qw(:DEFAULT setlogsock);
use Class::Accessor::Lite;

my $rwaccessors = [
    'facility',     # (String) syslog facility
    'loglevel',     # (String) default log level
    'disabled',     # (Integer) syslog disabled
    'option',       # (HashRef) Logging options
];
my $roaccessors = [
    'identity',     # (String) Log identiy string
    'queueid',      # (String) Queue ID
    'useragent',    # (String) User agent name
    'remoteaddr',   # (String) Client IP address
    'remoteport',   # (String) Client port number
];

Class::Accessor::Lite->mk_accessors( @$rwaccessors );
Class::Accessor::Lite->mk_ro_accessors( @$roaccessors );

# Set prefix or suffix into the log message
#  Emergency     (level 0)
#  Alert         (level 1)
#  Critical      (level 2)
#  Error         (level 3)
#  Warning       (level 4)
#  Notice        (level 5)
#  Info          (level 6)
#  Debug         (level 7)
my $LogLevels = [
    'emerg', 'alert', 'crit', 'err' ,
    'warning', 'notice', 'info', 'debug',
];

sub new {
    my $class = shift;
    my $argvs = { @_ };

    my $logoptions = {
        'cons'    => 0,
        'ndelay'  => 1,
        'noeol'   => 0,
        'nofatal' => 1,
        'nonul'   => 0,
        'nowait'  => 0,
        'perror'  => 0,
        'pid'     => 1,
    };

    $argvs->{'facility'}   ||= 'local2';
    $argvs->{'loglevel'}   ||= 'info';
    $argvs->{'loglevel'}     = 'info' unless grep { $argvs->{'loglevel'} eq $_ } @$LogLevels;
    $argvs->{'disabled'}   //= 0;
    $argvs->{'identity'}     = 'haineko';
    $argvs->{'queueid'}    //= q();
    $argvs->{'useragent'}  ||= q();
    $argvs->{'remoteaddr'} ||= q();
    $argvs->{'remoteport'} //= q();

    if( defined $argvs->{'option'} && ref $argvs->{'option'} eq 'HASH' ) {
        # Set logging options
        for my $e ( keys %$logoptions ) {
            $argvs->{'option'}->{ $e } //= $logoptions->{ $e };
        }

    } else {
        $argvs->{'option'} = $logoptions;
    }

    return bless $argvs, __PACKAGE__;
}

sub o {
    # Return syslog option as a string
    my $self = shift;
    my $opts = [ grep { $_ if $self->{'options'}->{ $_ } } keys %{ $self->{'options'} } ];
    return join( ',', @$opts );
}

sub h {
    # Return syslog header string
    my $self = shift;
    my $head = [];
    my $host = q();

    push @$head, sprintf( "queueid=%s", $self->{'queueid'} ) if $self->{'queueid'};
    $host  = sprintf( "client=%s", $self->{'remoteaddr'} ) if $self->{'remoteaddr'};
    $host .= sprintf( ":%d", $self->{'remoteport'} ) if $host && $self->{'remoteport'};
    push @$head, $host if length $host;
    push @$head, sprintf( "ua='%s'", $self->{'useragent'} ) if $self->{'useragent'};

    return q() unless scalar @$head;
    return join( ', ', @$head );
}

sub w {
    # write messages
    my $self = shift;
    my $sllv = shift || $self->{'loglevel'};
    my $mesg = shift;
    my $text = q();
    my $logs = [];

    return 0 if $self->{'disabled'};
    return 0 unless ref $mesg eq 'HASH';

    $sllv = 'info' unless grep { $sllv eq $_ } @$LogLevels;
    push @$logs, $self->h;

    for my $e ( keys %$mesg ) {

        next if ref $mesg->{ $e };
        next unless $mesg->{ $e };
        $text = $mesg->{ $e };
        $text = sprintf( "'%s'", $text ) if $text =~ m/\s/;
        push @$logs, sprintf( "%s=%s", $e, $text );
    }

    if( defined $mesg->{'message'} ) {

        if( ref $mesg->{'message'} eq 'ARRAY' ) {
            $text = sprintf( "message='%s'", join( ' | ', @{ $mesg->{'message'} } ) );
            push @$logs, $text;

        } else {
            push @$logs, sprintf( "message=%s", $mesg->{'message'} );
        }
    }

    openlog( $self->{'identify'}, $self->o, $self->{'facility'} ) || return 0;
    syslog( $sllv, join( ', ', @$logs ) ) || return 0;
    closelog || return 0;
    return 1;
}

1;
__END__

=encoding utf8

=head1 NAME

Haineko::Log - Syslog interface

=head1 DESCRIPTION

Write log messages via UNIX syslog

=head1 SYNOPSIS

    use Haineko::Log;
    my $v = { 
        'remoteaddr' => '127.0.0.1', 
        'remoteport' => 1024, 
    };
    my $e = Haineko::Log->new( %$v );
    my $x = { 'message' => 'Log message' };
    $e->w( 'info', $x );
    # Jul  4 10:00:00 host haineko[6994]: client=127.0.0.1:1024, message='Log message'

    $x = { 'message' => 'Rejected', 'dsn' => '5.2.1', 'code' => 550 };
    $e->w( 'err', $x );
    # Jul  4 10:00:00 host haineko[6994]: client=127.0.0.1:1024, message='Rejected', dsn=5.2.1, code=550

    $v = { 'remoteaddr' => '192.0.1.2', 'queueid' => 'r67HY3E06994bogA' };
    $e = Haineko::Log->new( %$v );
    $x = { 'message' => [ 'Log1', 'Log2' ] 'neko' => 'Nyaa' };
    $e->w( 'err', $x );
    # Jul  4 10:00:00 host haineko[6994]: queueid=r67HY3E06994bogA, client=192.0.2.1, message='Log1 | Log2', neko=Nyaa

=head1 CLASS METHODS

=head2 C<B<new( I<%arguments> )>>

C<new()> is a constructor of Haineko::Log

    my $e = Haineko::Log->new(
            'queueid' => 'ID string',   # Haineko::SMTPD::Session->queueid
            'useragent' => 'Agent name',    # $self->req->header->user_agent
            'remoteaddr' => '127.0.0.1',    # REMOTE_HOST http environment variable
            'remoteport' => 1024,       # REMOTE_PORT http environment variable
    );

=head1 INSTANCE METHODS

=head2 C<B<w( I<log-level>, I<argument>)>>

C<w()> write log messages via UNIX syslog

    my $e = Haineko:::Log->new( %argvs );
    my $m = { 'message' => 'error', 'cat' => 'kijitora' };
    $e->w( 'err', $m );

=head1 REPOSITORY

https://github.com/azumakuniyuki/Haineko

=head1 AUTHOR

azumakuniyuki E<lt>perl.org [at] azumakuniyuki.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.

=cut
