package Mail::AuthenticationResults::Header::AuthServID;
# ABSTRACT: Class modelling the AuthServID part of the Authentication Results Headerr

require 5.010;
use strict;
use warnings;
our $VERSION = '1.20180113'; # VERSION
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

sub as_string {
    my ( $self ) = @_;
    my $string = q{};
    return join( ' ', $self->stringify( $self->value() ), map { $_->as_string() } @{ $self->children() } );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::AuthenticationResults::Header::AuthServID - Class modelling the AuthServID part of the Authentication Results Headerr

=head1 VERSION

version 1.20180113

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
