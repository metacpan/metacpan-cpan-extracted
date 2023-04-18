
use strict;
use warnings;

package Zest::Author::TABULO::Util::Mayhap;
our $VERSION = '1.000012';

use PerlX::Maybe qw(maybe);
use Exporter::Shiny qw(mayhap);


#region: #== UTILITY FUNCTIONS (EXPORT_OK) ==

## no critic: Prototypes
sub mayhap ($$@) { # the prototype is intentional here.
    my ( $arg1, $arg2 ) = ( shift, shift );
    maybe $arg1 => _undef_if_empty($arg2), @_;
}

sub _undef_if_empty { # Utility function
    my $x = shift;
    for ( ref $x // () ) {
        m/ARRAY/ and do { return ( @$x ? $x : undef ) };
        m/HASH/  and do { return ( %$x ? $x : undef ) };
    }
    $x;
}

#endregion (UTILITY FUNCTIONS)

1;

=pod

=encoding UTF-8

=for :stopwords Tabulo[n]

=head1 NAME

Zest::Author::TABULO::Util::Mayhap - Utility functions used by TABULO's authoring dist

=head1 VERSION

version 1.000012

=for Pod::Coverage mayhap

=head1 AUTHORS

Tabulo[n] <dev@tabulo.net>

=head1 LEGAL

This software is copyright (c) 2023 by Tabulo[n].

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#ABSTRACT: Utility functions used by TABULO's authoring dist

## TODO: Actually document some of the below
