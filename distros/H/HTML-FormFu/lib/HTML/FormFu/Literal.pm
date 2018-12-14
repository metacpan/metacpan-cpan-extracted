use strict;

package HTML::FormFu::Literal;
# ABSTRACT: a FormFu literal
$HTML::FormFu::Literal::VERSION = '2.07';
use warnings;

use HTML::FormFu::Constants qw( $EMPTY_STR );

use overload
    '""'     => sub { return join $EMPTY_STR, @{ $_[0] } },
    fallback => 1;

sub new {
    my $class = shift;

    return bless \@_, $class;
}

sub push {
    my ( $self, @args ) = @_;

    CORE::push( @{ $_[0] }, @args );
}

sub unshift {
    my ( $self, @args ) = @_;

    CORE::unshift( @{ $_[0] }, @args );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Literal - a FormFu literal

=head1 VERSION

version 2.07

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
