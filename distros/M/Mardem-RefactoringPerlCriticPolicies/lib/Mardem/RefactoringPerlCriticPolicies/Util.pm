package Mardem::RefactoringPerlCriticPolicies::Util;

use utf8;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.01';

use Readonly;
use List::Util qw( first );

use Perl::Critic::Utils qw{ is_hash_key };

use base 'Exporter';

our @EXPORT_OK = qw( search_for_block_keyword );

Readonly::Array my @BLOCK_SEARCH_KEYWORD => qw(
    SUB
    IF ELSIF UNLESS
    WHILE UNTIL
    DO
    FOR FOREACH
    EVAL
    SORT MAP GREP
    BEGIN UNITCHECK CHECK INIT END
    PACKAGE );

Readonly::Scalar my $MAX_KEYWORD_LOOKUP_DEPTH => 10;

sub _keyword_in_searchlist
{
    my ( $keyword ) = @_;

    $keyword = uc $keyword;

    my $found = first { $_ eq $keyword } @BLOCK_SEARCH_KEYWORD;

    return $found;
}

sub search_for_block_keyword
{
    my ( $elem ) = @_;

    if ( !ref $elem ) {
        last;
    }

    my $word_search   = $elem;
    my $block_keyword = q{};

    my $i = 1;

    while ( !$block_keyword ) {
        if ( $i >= $MAX_KEYWORD_LOOKUP_DEPTH ) {
            last;    # recurse abort!
        }

        my $sprevious = $word_search->sprevious_sibling;

        if ( !$sprevious || $sprevious == $word_search ) {
            last;
        }

        if ( !is_hash_key( $sprevious ) ) {
            $word_search = $sprevious;

            my $content_search = $word_search->content;

            $block_keyword = _keyword_in_searchlist( $content_search );
        }

        $i++;
    }

    return $block_keyword;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=encoding utf8

=head1 NAME

Mardem::RefactoringPerlCriticPolicies::Util - Internal Util module!

=head1 DESCRIPTION

Util module with internal subroutines for the
L<Perl::Critic::Policy::Mardem>> modules.

=head1 AFFILIATION

This policy is part of L<Mardem::RefactoringPerlCriticPolicies>.

=head1 AUTHOR

Markus Demml, mardem@cpan.com

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2022, Markus Demml

This library is free software; you can redistribute it and/or modify it
under the same terms as the Perl 5 programming language system itself.
The full text of this license can be found in the LICENSE file included
with this module.

=cut
