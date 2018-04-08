package IO::Stream::MatrixSSL::Server;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.0.2';

use IO::Stream::const;
use IO::Stream::MatrixSSL::const;
use Crypt::MatrixSSL3 qw( :all );
use Scalar::Util qw( weaken );

use parent qw( -norequire IO::Stream::MatrixSSL );


sub new {
    my ($class, $opt) = @_;
    croak '{crt} and {key} required'
        if !defined $opt->{crt} || !defined $opt->{key};
    my $self = bless {
        crt         => undef,       # filename(s) with server's certificate(s)
        key         => undef,       # filename with server's private key
        pass        => undef,       # password to decrypt private key
        trusted_CA  => undef,       # filename(s) with trusted root CA cert(s)
        cb          => undef,       # callback for validating certificate
        %{$opt // {}},
        out_buf     => q{},                 # modified on: OUT
        out_pos     => undef,               # modified on: OUT
        out_bytes   => 0,                   # modified on: OUT
        in_buf      => q{},                 # modified on: IN
        in_bytes    => 0,                   # modified on: IN
        ip          => undef,               # modified on: RESOLVED
        is_eof      => undef,               # modified on: EOF
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
    $self->{_ssl} = Crypt::MatrixSSL3::Server->new($self->{_ssl_keys}, $cb);
    return $self;
}

sub PREPARE {
    my ($self, $fh, $host, $port) = @_;
    if (!defined $host) {   # ... else timer will be set on CONNECTED
        $self->{_t} = EV::timer(TOHANDSHAKE, 0, $self->{_cb_t});
    }
    $self->{_slave}->PREPARE($fh, $host, $port);
    return;
}


1;
