package Log::Handler::Output::Gearman;

use strict;
use warnings;
use Carp::Clan qw(^Log::Handler);
use Gearman::XS::Client;
use Gearman::XS qw(:constants);
use Params::Validate;

our $VERSION = '0.01003';
our $ERRSTR  = '';

=head1 NAME

Log::Handler::Output::Gearman - Send log messages to Gearman workers.

=head1 SYNOPSIS

    use Log::Handler::Output::Gearman;

    my $logger = Log::Handler::Output::Gearman->new(
        servers => ['127.0.0.1:4731'],
        worker  => 'logger',
    );

    my $message = 'This is a log message';
    $logger->log( $message );

=head1 DESCRIPTION

B<This is experimental ( beta ) and should only be used in a test environment. The
API may change at any time without prior notification until this message is removed!>

=head1 METHODS

=head2 new

Takes a number of arguments, following are B<mandatory>:

=over 4

=item *

servers

    # hostname:port gearmand is running on
    servers => [
        '127.0.0.1:4731',
        '192.168.0.1:4735',
        '192.168.0.2'       # uses default port (4730)
    ]

=item *

worker

    # name of the worker that should process the log messages
    worker => 'logger'

=back

Besides it takes also following B<optional> arguments:

=over 4

=item *

method (default: do_background)

    method => 'do_high_background'

This can be one of the following L<Gearman::XS::Client> methods:

=over 4

=item * C<do>

=item * C<do_high>

=item * C<do_low>

=item * C<do_background>

=item * C<do_high_background>

=item * C<do_low_background>

=back

=back

=cut

sub new {
    my $package = shift;

    my %options = $package->_validate(@_);

    my $self = bless \%options, $package;

    $self->_setup_gearman;

    return $self;
}

=head2 log

Takes one argument:

=over 4

=item *

C<$message> - The log message

=back

=cut

sub log {
    my ( $self, $message ) = @_;

    return unless defined $message;

    $message = $message->{message} if ref($message) eq 'HASH' and defined $message->{message};

    my $method  = $self->{method};
    my $worker  = $self->{worker};

    my $workload = $message;

    my ( $ret, $job_handle ) = $self->{client}->$method( $worker, $workload );
    if ( $ret != GEARMAN_SUCCESS ) {
        return $self->_raise_error( $self->{client}->error() );
    }

    return 1;
}

=head2 errstr

Returns the last error message.

=cut

sub errstr { $ERRSTR }

=head2 gearman_client

Returns L<Gearman::XS::Client> instance.

=cut

sub gearman_client {
    return shift->{client};
}

=head2 reload

Reload with a new configuration.

=cut

sub reload {
    my $self = shift;

    my %options = ();
    eval { %options = $self->_validate(@_) };

    if ($@) {
        return $self->_raise_error($@);
    }

    foreach my $key (keys %options) {
        $self->{$key} = $options{$key};
    }

    $self->_setup_gearman;

    return 1;
}

sub _setup_gearman {
    my ($self) = @_;
    my $client = Gearman::XS::Client->new;
    my $ret = $client->add_servers( join( ',', @{ $self->{servers} } ) );
    if ( $ret != GEARMAN_SUCCESS ) {
        croak( $client->error() );
    }
    $self->{client} = $client;
}

sub _raise_error {
    my $self = shift;
    $ERRSTR = shift;
    return undef;
}

sub _validate {
    my $self = shift;
    return Params::Validate::validate(
        @_,
        {
            servers => {
                type     => Params::Validate::ARRAYREF,
                optional => 0,
            },
            worker => {
                type     => Params::Validate::SCALAR,
                optional => 0,
            },
            method => {
                type    => Params::Validate::SCALAR,
                regex   => qr/^(do|do_high|do_low|do_background|do_high_background|do_low_background)$/,
                default => 'do_background',
            },
        }
    );
}

=head1 AUTHOR

Johannes Plunien E<lt>plu@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Johannes Plunien

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4 

=item * L<Log::Handler>

=item * L<Gearman::XS::Client>

=item * L<http://www.gearman.org/>

=back

=head1 REPOSITORY

L<http://github.com/plu/log-handler-output-gearman/>

=cut

1;
