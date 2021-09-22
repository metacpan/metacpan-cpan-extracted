package Mail::AuthenticationResults::Header::Version;
# ABSTRACT: Class modelling the AuthServID part of the Authentication Results Header

require 5.008;
use strict;
use warnings;
our $VERSION = '2.20210915'; # VERSION
use Scalar::Util qw{ weaken };
use Carp;

use base 'Mail::AuthenticationResults::Header::Base';


sub _HAS_VALUE{ return 1; }

sub build_string {
    my ( $self, $header ) = @_;

    if ( ! $self->value() ) {
        return;
    }

    if ( ref $self->parent() ne 'Mail::AuthenticationResults::Header::AuthServID' ) {
        $header->separator( '/' );
        $header->space( ' ' );
    }

    $header->string( $self->value() );

    return;
}

sub safe_set_value {
    my ( $self, $value ) = @_;

    $value = 1 if ! defined $value;
    $value =~ s/[^0-9]//g;
    $value = 1 if $value eq q{};

    $self->set_value( $value );
    return $self;
}

sub set_value {
    my ( $self, $value ) = @_;

    croak 'Does not have value' if ! $self->_HAS_VALUE(); # uncoverable branch true
    # HAS_VALUE is 1 for this class
    croak 'Value cannot be undefined' if ! defined $value;
    croak 'Value must be numeric' if $value =~ /[^0-9]/;

    $self->{ 'value' } = $value;
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::AuthenticationResults::Header::Version - Class modelling the AuthServID part of the Authentication Results Header

=head1 VERSION

version 2.20210915

=head1 DESCRIPTION

A version string, this may be associated with an AuthServID, Entry, Group, or SubEntry.

Please see L<Mail::AuthenticationResults::Header::Base>

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
