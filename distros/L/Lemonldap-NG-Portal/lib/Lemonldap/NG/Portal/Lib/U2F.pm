package Lemonldap::NG::Portal::Lib::U2F;

use strict;
use Mouse;
use MIME::Base64 qw(encode_base64 decode_base64);

our $VERSION = '2.0.0';

has origin => ( is => 'rw', );

sub init {
    my ($self) = @_;
    eval 'use Crypt::U2F::Server::Simple';
    if ($@) {
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

sub encode_base64url {
    shift;
    my $e = encode_base64( shift, '' );
    $e =~ s/=+\z//;
    $e =~ tr[+/][-_];
    return $e;
}

sub decode_base64url {
    shift;
    my $s = shift;
    $s =~ tr[-_][+/];
    $s .= '=' while length($s) % 4;
    return decode_base64($s);
}

1;
