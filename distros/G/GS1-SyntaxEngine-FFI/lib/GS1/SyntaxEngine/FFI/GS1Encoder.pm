# SPDX-License-Identifier: GPL-1.0-or-later OR Artistic-1.0-Perl

package GS1::SyntaxEngine::FFI::GS1Encoder;
$GS1::SyntaxEngine::FFI::GS1Encoder::VERSION = '0.2';
use utf8;

use strictures 2;
use namespace::clean;

use FFI::Platypus 2.08;
use FFI::Platypus::Memory ();

use Alien::libgs1encoders 0.03;

my $ffi = FFI::Platypus->new(
    api => 2,
    lib => [ Alien::libgs1encoders->dynamic_libs ]
);
$ffi->mangler(
    sub {
        my ($name) = @_;
        "gs1_encoder$name";
    }
);

$ffi->attach( _instanceSize        => ['void']                   => 'size_t' );
$ffi->attach( _init                => ['opaque']                 => 'int' );
$ffi->attach( _getVersion          => ['opaque']                 => 'string' );
$ffi->attach( _getErrMsg           => ['opaque']                 => 'string' );
$ffi->attach( _getSym              => ['opaque']                 => 'int' );
$ffi->attach( _setSym              => [ 'opaque', 'int' ]        => 'bool' );
$ffi->attach( _getAddCheckDigit    => ['opaque']                 => 'bool' );
$ffi->attach( _setAddCheckDigit    => [ 'opaque', 'bool' ]       => 'bool' );
$ffi->attach( _getPermitUnknownAIs => ['opaque']                 => 'bool' );
$ffi->attach( _setPermitUnknownAIs => [ 'opaque', 'bool' ]       => 'bool' );
$ffi->attach( _getPermitZeroSuppressedGTINinDLuris => ['opaque'] => 'bool' );
$ffi->attach(
    _setPermitZeroSuppressedGTINinDLuris => [ 'opaque', 'bool' ] => 'bool' );
$ffi->attach( _getIncludeDataTitlesInHRI => ['opaque']           => 'bool' );
$ffi->attach( _setIncludeDataTitlesInHRI => [ 'opaque', 'bool' ] => 'bool' );
$ffi->attach( _getValidateAIassociations => ['opaque']           => 'bool' );
$ffi->attach( _setValidateAIassociations => [ 'opaque', 'bool' ] => 'bool' );
$ffi->attach( _getDLuri     => [ 'opaque', 'string' ]            => 'string' );
$ffi->attach( _getScanData  => ['opaque']                        => 'string' );
$ffi->attach( _setScanData  => [ 'opaque', 'string' ]            => 'bool' );
$ffi->attach( _getDataStr   => ['opaque']                        => 'string' );
$ffi->attach( _setDataStr   => [ 'opaque', 'string' ]            => 'bool' );
$ffi->attach( _getAIdataStr => ['opaque']                        => 'string' );
$ffi->attach( _setAIdataStr => [ 'opaque', 'string' ]            => 'bool' );

sub new {
    my ($class) = @_;
    my $size    = _instanceSize();
    my $self    = bless \FFI::Platypus::Memory::malloc($size), $class;
    my $r       = _init( ${$self} );
    return $self;
}

sub _throw_error_exception {
    my ($self) = @_;
    GS1::SyntaxEngine::FFI::EncoderParameterException->throw(
        { message => $self->error_msg } );
    return;
}

sub ai_data_str {
    my ( $self, $value ) = @_;
    if ( @_ == 2 ) {
        _setAIdataStr( ${$self}, $value ) or $self->_throw_error_exception();
    }

    return _getAIdataStr( ${$self} );
}

sub data_str {
    my ( $self, $value ) = @_;
    if ( @_ == 2 ) {
        _setDataStr( ${$self}, $value ) or $self->_throw_error_exception();
    }

    return _getDataStr( ${$self} );
}

sub scan_data {
    my ( $self, $value ) = @_;
    if ( @_ == 2 ) {
        _setScanData( ${$self}, $value ) or $self->_throw_error_exception();
    }

    return _getScanData( ${$self} );
}

sub error_msg {
    my ($self) = @_;
    return _getErrMsg( ${$self} );
}

sub add_check_digit {
    my ( $self, $value ) = @_;
    if ( @_ == 2 ) {
        _setAddCheckDigit( ${$self}, $value )
          or $self->_throw_error_exception();
    }

    return _getAddCheckDigit( ${$self} );
}

sub permit_unknown_ais {
    my ( $self, $value ) = @_;
    if ( @_ == 2 ) {
        _setPermitUnknownAIs( ${$self}, $value )
          or $self->_throw_error_exception();
    }

    return _getPermitUnknownAIs( ${$self} );
}

sub permit_zero_suppressed_gtin_in_dl_uris {
    my ( $self, $value ) = @_;
    if ( @_ == 2 ) {
        _setPermitZeroSuppressedGTINinDLuris( ${$self}, $value )
          or $self->_throw_error_exception();
    }

    return _getPermitZeroSuppressedGTINinDLuris( ${$self} );
}

sub include_data_titles_in_hri {
    my ( $self, $value ) = @_;
    if ( @_ == 2 ) {
        _setIncludeDataTitlesInHRI( ${$self}, $value )
          or $self->_throw_error_exception();
    }

    return _getIncludeDataTitlesInHRI( ${$self} );
}

sub validate_ai_associations {
    my ( $self, $value ) = @_;
    if ( @_ == 2 ) {
        _setValidateAIassociations( ${$self}, $value )
          or $self->_throw_error_exception();
    }

    return _getValidateAIassociations( ${$self} );
}

sub version {
    my ($self) = @_;
    return _getVersion( ${$self} );
}

sub dl_uri {
    my ( $self, $domain ) = @_;
    return _getDLuri( ${$self}, $domain );
}

sub DESTROY {
    my ($self) = @_;
    FFI::Platypus::Memory::free( ${$self} );
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

GS1::SyntaxEngine::FFI::GS1Encoder

=head1 VERSION

version 0.2

=head1 AUTHOR

hangy

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by hangy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
