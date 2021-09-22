package Mail::AuthenticationResults::Token::Assignment;
# ABSTRACT: Class for modelling AuthenticationResults Header parts detected as assignments

require 5.008;
use strict;
use warnings;
our $VERSION = '2.20210915'; # VERSION
use Carp;

use base 'Mail::AuthenticationResults::Token';


sub is {
    my ( $self ) = @_;
    return 'assignment';
}

sub parse {
    my ($self) = @_;

    my $header = $self->{ 'header' };
    my $value = q{};

    my $first = substr( $header,0,1 );
    if ( $first ne '=' && $first ne '.' && $first ne '/' ) {
        croak 'not an assignment';
    }

    $header   = substr( $header,1 );

    $self->{ 'value' } = $first;
    $self->{ 'header' } = $header;

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::AuthenticationResults::Token::Assignment - Class for modelling AuthenticationResults Header parts detected as assignments

=head1 VERSION

version 2.20210915

=head1 DESCRIPTION

Token representing an assignment operator

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
