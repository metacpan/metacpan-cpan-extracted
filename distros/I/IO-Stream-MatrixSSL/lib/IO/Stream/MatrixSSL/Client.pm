package IO::Stream::MatrixSSL::Client;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.0.1';

use IO::Stream::const;
use IO::Stream::MatrixSSL::const;
use Crypt::MatrixSSL3 qw( :all );
use Scalar::Util qw( weaken );

use parent qw( -norequire IO::Stream::MatrixSSL );


sub new {
    my ($class, $opt) = @_;
    my $self = bless {
        crt         => undef,       # filename(s) with client's certificate(s)
        key         => undef,       # filename with client's private key
        pass        => undef,       # password to decrypt private key
        trusted_CA  => $Crypt::MatrixSSL3::CA_CERTIFICATES, # filename(s) with trusted root CA cert(s)
        cb          => undef,       # callback for validating certificate
        %{$opt // {}},
        out_buf     => q{},                 # modified on: OUT
        out_pos     => undef,               # modified on: OUT
        out_bytes   => 0,                   # modified on: OUT
        in_buf      => q{},                 # modified on: IN
        in_bytes    => 0,                   # modified on: IN
        ip          => undef,               # modified on: RESOLVED
        is_eof      => undef,               # modified on: EOF
        # TODO Make this field public and add feature 'restore session'.
        # _ssl_session=> undef,       # MatrixSSL 'sessionId' object
        _ssl        => undef,       # MatrixSSL 'session' object
        _ssl_keys   => undef,       # MatrixSSL 'keys' object
        _handshaked => 0,           # flag, will be true after handshake
        _want_write => 0,           # flag, will be true if write() was called before handshake
        _want_close => 0,           # flag, will be true after generating MATRIXSSL_REQUEST_CLOSE
        _closed     => 0,           # flag, will be true after sending MATRIXSSL_REQUEST_CLOSE
        _t          => undef,
        _cb_t       => undef,
        }, $class;
    weaken(my $this = $self);
    $self->{_cb_t} = sub { $this && $this->T() };
    my $cb = !$self->{cb} ? undef : sub {
        $this ? $this->{cb}->($this, @_) : CERTVALIDATOR_INTERNAL_ERROR
    };
    # Initialize SSL.
    # TODO OPTIMIZATION Cache {_ssl_keys}.
    $self->{_ssl_keys} = Crypt::MatrixSSL3::Keys->new();
    my $rc = $self->{_ssl_keys}->load_rsa(
        $self->{crt}, $self->{key}, $self->{pass}, $self->{trusted_CA}
    );
    croak 'ssl error: '.get_ssl_error($rc) if $rc != PS_SUCCESS;
    # TODO OPTIMIZATION Use {_ssl_session}.
    # TODO Add feature: let user provide @cipherSuites.
    # TODO Add feature: let user provide $expectedName.
    $self->{_ssl} = Crypt::MatrixSSL3::Client->new(
        $self->{_ssl_keys}, undef, undef, $cb, undef, undef, undef
    );
    $rc = $self->{_ssl}->sent_data( $self->{_ssl}->get_outdata($self->{out_buf}) );
    croak 'ssl error: '.get_ssl_error($rc) if $rc != PS_SUCCESS;
    return $self;
}

sub PREPARE {
    my ($self, $fh, $host, $port) = @_;
    if (!defined $host) {   # ... else timer will be set on CONNECTED
        $self->{_t} = EV::timer(TOHANDSHAKE, 0, $self->{_cb_t});
    }
    $self->{_slave}->PREPARE($fh, $host, $port);
    $self->{_slave}->WRITE();                       # output 'client hello'
    return;
}


1;
