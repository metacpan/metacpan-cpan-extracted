package Log::Dispatch::Log::Syslog::Fast;

use strict;
use warnings;

our $VERSION = '1.00';

use Log::Dispatch::Output;
use parent qw( Log::Dispatch::Output );

use Carp qw( croak );
use Log::Syslog::Constants 1.02 qw( :functions :severities );
use Log::Syslog::Fast 0.58 qw( :protos );
use Params::Validate qw( validate SCALAR );
use Sys::Hostname ();

Params::Validate::validation_options( allow_extra => 1 );

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %p = @_;

    my $self = bless {}, $class;

    $self->_basic_init(%p);
    $self->_init(%p);

    return $self;
}

my ($Ident) = $0 =~ /(.+)/;

sub _init {
    my $self = shift;

    my %p = validate(
        @_, {
            transport => {
                type    => SCALAR,
                default => 'udp',
            },
            host => {
                type    => SCALAR,
                default => 'localhost',
            },
            port => {
                type    => SCALAR,
                default => 514,
            },
            facility => {
                type    => SCALAR,
                default => 'user'
            },
            severity => {
                type    => SCALAR,
                default => 'info'
            },
            sender => {
                type    => SCALAR,
                default => Sys::Hostname::hostname(),
            },
            name => {
                type    => SCALAR,
                default => $Ident
            },
        }
    );

    my $transport
        = lc $p{transport} eq 'udp'  ? LOG_UDP
        : lc $p{transport} eq 'tcp'  ? LOG_TCP
        : lc $p{transport} eq 'unix' ? LOG_UNIX
        : undef;
    croak "unknown facility $p{facility}" unless defined $transport;

    $self->{facility} = get_facility($p{facility});
    croak "unknown facility $p{facility}" unless defined $self->{facility};

    $self->{severity} = get_severity($p{severity});
    croak "unknown severity $p{severity}" unless defined $self->{severity};

    my $logger = Log::Syslog::Fast->new(
        $transport, $p{host}, $p{port},
        $self->{facility}, $self->{severity},
        $p{sender}, $p{name},
    );
    die "failed to create Log::Syslog::Fast" unless $logger;

    $self->{logger} = $logger;
}

# mapping of levels defined in Log::Dispatch to syslog severity
my %level2severity = (
    0           => LOG_DEBUG,
    debug       => LOG_DEBUG,

    1           => LOG_INFO,
    info        => LOG_INFO,

    2           => LOG_NOTICE,
    notice      => LOG_NOTICE,

    3           => LOG_WARNING,
    warn        => LOG_WARNING,
    warning     => LOG_WARNING,

    4           => LOG_ERR,
    error       => LOG_ERR,
    err         => LOG_ERR,

    5           => LOG_CRIT,
    critical    => LOG_CRIT,
    crit        => LOG_CRIT,

    6           => LOG_ALERT,
    alert       => LOG_ALERT,

    7           => LOG_EMERG,
    emergency   => LOG_EMERG,
    emerg       => LOG_EMERG,
);

sub log_message {
    my ($self, %p) = @_;

    if (defined(my $level = $p{level})) {
        if (defined(my $severity = $level2severity{lc $level})) {
            if ($severity != $self->{severity}) {
                $self->{severity} = $severity;
                $self->{logger}->set_severity($self->{severity});
            }
        }
    }

    $self->{logger}->send($p{message});
}

1;

# ABSTRACT: Log::Dispatch wrapper around Log::Syslog::Fast


__END__
=pod

=head1 NAME

Log::Dispatch::Log::Syslog::Fast - Log::Dispatch wrapper around Log::Syslog::Fast

=head1 VERSION

version 1.02

=head1 SYNOPSIS

  use Log::Dispatch;

  my $log = Log::Dispatch->new(
      outputs => [
          [
              'Log::Syslog::Fast',
              min_level => 'info',
              name      => 'Yadda yadda'
          ]
      ]
  );

  $log->emerg("Time to die.");

=head1 DESCRIPTION

This module provides a simple object for sending messages to a syslog daemon
via UDP, TCP, or UNIX socket.

=head1 METHODS

=head2 new

The constructor takes the following parameters in addition to the standard
parameters documented in L<Log::Dispatch::Output>:

=item * transport ($)

The transport mechanism to use: one of 'udp', 'tcp', or 'unix'.

=item * host ($)

For UDP and TCP, the hostname or IPv4 or IPv6 address. For UNIX, the socket
path. Defaults to 'localhost'.

=item * port ($)

The listening port of the syslogd (ignored for unix sockets). See
Log::Syslog::Fast. Defaults to 514.

=item * facility ($)

The log facility to use. See Log::Syslog::Constants. Defaults to 'user'.

=item * severity ($)

The log severity to use. See Log::Syslog::Constants. Defaults to 'info'.

=item * sender ($)

The system name to claim as the source of the message. Defaults to the system's
hostname.

=item * name ($)

The name of the application. Defaults to $0.

=head1 AUTHOR

Adam Thomason <athomason@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Adam Thomason.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

