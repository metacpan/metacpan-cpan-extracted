package Mail::AuthenticationResults::Token::Separator;
# ABSTRACT: Class for modelling AuthenticationResults Header parts detected as separators

require 5.008;
use strict;
use warnings;
our $VERSION = '2.20210915'; # VERSION
use Carp;

use base 'Mail::AuthenticationResults::Token';


sub is {
    my ( $self ) = @_;
    return 'separator';
}

sub parse {
    my ($self) = @_;

    my $header = $self->{ 'header' };
    my $value = q{};

    my $first = substr( $header,0,1 );
    croak 'not a separator' if $first ne ';';

    $header   = substr( $header,1 );

    $self->{ 'value' } = ';';
    $self->{ 'header' } = $header;

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::AuthenticationResults::Token::Separator - Class for modelling AuthenticationResults Header parts detected as separators

=head1 VERSION

version 2.20210915

=head1 DESCRIPTION

Token representing a separator

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
