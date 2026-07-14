package Digest::xxHash;
use strict;
use warnings;
use base   qw[Exporter];
use Config ();
use XSLoader;

BEGIN {
    our $VERSION = '3.00';
    XSLoader::load __PACKAGE__, $VERSION;
}
our @EXPORT_OK = qw[
    xxhash32 xxhash32_hex
    xxhash64 xxhash64_hex
    xxh3_64 xxh3_64_hex
    xxh3_128 xxh3_128_hex
    xxh3_generate_secret
];
sub xxh3_generate_secret { xxh3_generate_secret_from_seed(@_) }
my %TYPE_CODES = ( xxh32 => 0, xxh64 => 1, xxh3_64 => 2, xxh3_128 => 3 );

sub new {
    my ( $class, %args ) = @_;
    my $type   = delete $args{type} // 'xxh32';
    my $seed   = delete $args{seed} // 0;
    my $secret = delete $args{secret};
    if (%args) {
        require Carp;
        Carp::croak( 'Unknown arguments: ' . join( ', ', sort keys %args ) );
    }
    my $type_code = $TYPE_CODES{$type};
    unless ( defined $type_code ) {
        require Carp;
        Carp::croak("Unknown hash type: $type");
    }
    my $self = bless { type => $type, type_code => $type_code, seed => $seed, secret => $secret }, $class;
    $self->_init;
    return $self;
}

sub _init {
    my ($self) = @_;
    $self->{ctx} = _xxxh_create( $self->{type_code} );
    if ( defined $self->{secret} ) {
        _xxxh_reset_withSecret( $self->{ctx}, $self->{type_code}, $self->{secret} );
    }
    else {
        _xxxh_reset( $self->{ctx}, $self->{type_code}, $self->{seed} );
    }
}

sub add {
    my ( $self, @etc ) = @_;
    my $ctx = $self->{ctx};
    my $tc  = $self->{type_code};
    _xxxh_update( $ctx, $_, $tc ) for @etc;
    return $self;
}
sub digest    { return _xxxh_digest( $_[0]->{ctx}, $_[0]->{type_code} ) }
sub hexdigest { return _xxxh_hex( $_[0]->{ctx}, $_[0]->{type_code} ) }

sub b64digest {
    require MIME::Base64;
    return MIME::Base64::encode_base64( $_[0]->digest, '' );
}

sub clone {
    my ($self) = @_;
    my $clone  = bless {%$self}, ref($self);
    my $tc     = $clone->{type_code};
    $clone->{ctx} = _xxxh_create($tc);
    _xxxh_copy( $clone->{ctx}, $self->{ctx}, $tc );
    return $clone;
}

sub reset {
    my ($self) = @_;
    $self->_init;
    return $self;
}

sub DESTROY {
    my ($self) = @_;
    return unless defined $self->{ctx};
    _xxxh_free( $self->{ctx}, $self->{type_code} );
    delete $self->{ctx};
}
1;
