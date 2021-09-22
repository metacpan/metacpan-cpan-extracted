package Mail::AuthenticationResults::Header::AuthServID;
# ABSTRACT: Class modelling the AuthServID part of the Authentication Results Headerr

require 5.008;
use strict;
use warnings;
our $VERSION = '2.20210915'; # VERSION
use Carp;

use base 'Mail::AuthenticationResults::Header::Base';


sub _HAS_VALUE{ return 1; }

sub _HAS_CHILDREN{ return 1; }

sub _ALLOWED_CHILDREN {
    my ( $self, $child ) = @_;
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::Comment';
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::SubEntry';
    return 1 if ref $child eq 'Mail::AuthenticationResults::Header::Version';
    return 0;
}

sub build_string {
    my ( $self, $header ) = @_;

    $header->string( $self->stringify( $self->value() ) );
    foreach my $child ( @{ $self->children() } ) {
        $header->space( ' ' );
        #$header->concat( $child->as_string_prefix() );
        $child->build_string( $header );
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::AuthenticationResults::Header::AuthServID - Class modelling the AuthServID part of the Authentication Results Headerr

=head1 VERSION

version 2.20210915

=head1 DESCRIPTION

The AuthServID is typically the first section of an Authentication Results Header, it records
the server responsible for performing the Authentication Results checks, and can additionally hold
a version number (assumed to be 1 if not present).

Some providers also add additional sub entries to the field, hence this class is capable of
being a parent to version, comment, and sub entry types.

This class is set as the value for a Mail::AuthenticationResults::Header class.

Please see L<Mail::AuthenticationResults::Header::Base>

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
