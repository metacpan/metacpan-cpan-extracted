package Mail::AuthenticationResults::Token::Space;
# ABSTRACT: Class for modelling AuthenticationResults Header parts detected as spaces

require 5.008;
use strict;
use warnings;
our $VERSION = '2.20261029'; # VERSION
use Carp;

use base 'Mail::AuthenticationResults::Token';


sub is {
    my ( $self ) = @_;
    return 'space';
}

sub new {
    my ($self) = @_;
    croak 'Space tokens are not used in parsing';
}

sub parse {
    my ($self) = @_;
    croak 'Space tokens are not used in parsing';
}

sub remainder {
    my ($self) = @_;
    croak 'Space tokens are not used in parsing';
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::AuthenticationResults::Token::Space - Class for modelling AuthenticationResults Header parts detected as spaces

=head1 VERSION

version 2.20261029

=head1 DESCRIPTION

Token representing a space

=head1 AUTHOR

Jemma Bradshaw <jemma@nothingbutstatic.dev>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Jemma Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
