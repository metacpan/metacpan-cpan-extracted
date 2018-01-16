package Mail::AuthenticationResults::Token;
# ABSTRACT: Base class for modelling AuthenticationResults Header parts

require 5.010;
use strict;
use warnings;
our $VERSION = '1.20180113'; # VERSION
use Carp;


sub new {
    my ( $class, $header, $args ) = @_;

    my $self = { 'args' => $args };
    bless $self, $class;

    $self->{ 'header' } = $header;
    $self->parse();

    return $self;
}


sub value {
    my ( $self ) = @_;
    return $self->{ 'value' };
}


sub remainder {
    my ( $self ) = @_;
    return $self->{ 'header' };
}


sub parse {
    my ( $self ) = @_;
    croak 'parse not implemented';
}


sub is { # uncoverable subroutine
    # a base Token cannot be instantiated, and all subclasses should implement this method.
    my ( $self ) = @_; # uncoverable statement
    croak 'is not implemented'; # uncoverable statement
}

1;;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::AuthenticationResults::Token - Base class for modelling AuthenticationResults Header parts

=head1 VERSION

version 1.20180113

=head1 METHODS

=head2 new( $header, $args )

Return a new Token object parsed from the given $header string using $args

$args value depend on the subclass of Token used

=head2 value()

Return the value of the current Token instance.

=head2 remainder()

Return the remainder of the header string after parsing the current token out.

=head2 parse()

Run the parser on the current $header and set up value() and remainder().

=head2 is()

Return the type of token we are.

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
