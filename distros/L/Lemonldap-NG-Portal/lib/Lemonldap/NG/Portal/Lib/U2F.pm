package Lemonldap::NG::Portal::Lib::U2F;

use strict;
use Mouse;

our $VERSION = '2.0.16';

has origin => ( is => 'rw', );

sub init {
    my ($self) = @_;
    eval { require Crypt::U2F::Server::Simple };
    if ($@) {
        $self->logger->error("Can't load U2F library: $@");
        $self->error("Can't load U2F library: $@");
        return 0;
    }
    my $p = $_[0]->{conf}->{portal};
    $p =~ s#^(https?://[^/]+).*$#$1#;
    $self->origin($p);

    # Test if a new object can be created
    unless (
        Crypt::U2F::Server::Simple->new(
            appId  => $self->origin,
            origin => $self->origin,
            ( $self->conf->{logLevel} eq 'debug' ? ( debug => 1 ) : () ),
        )
      )
    {
        $self->error( Crypt::U2F::Server::Simple::lastError() );
        return 0;
    }
    return 1;
}

sub crypter {
    my ( $self, %args ) = @_;
    return Crypt::U2F::Server::Simple->new(
        appId  => $self->origin,
        origin => $self->origin,
        ( $self->conf->{logLevel} eq 'debug' ? ( debug => 1 ) : () ),
        %args,
    );
}

1;
