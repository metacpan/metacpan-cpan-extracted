package Lingua::Orthon;
use 5.006;
use strict;
use warnings FATAL => 'all';
use Carp qw(croak);
use List::AllUtils qw(any);
use Number::Misc qw(is_numeric);
use Statistics::Lite qw(mean);
use String::Util qw(hascontent nocontent);
use Unicode::Collate;

$Lingua::Orthon::VERSION = '0.03';

=pod

=encoding CP-1252

=head1 NAME

Lingua-Orthon - Orthographic similarity of string to one or more others by Coltheart's N and related measures

=head1 VERSION

This is documentation for B<Version 0.03> of Lingua::Orthon.

=head1 SYNOPSIS

 use Lingua::Orthon 0.03;
 my $orthon = Lingua::Orthon->new();
 my $bool = $orthon->are_orthons('BANG', 'BARN'); # 0
 $bool = $orthon->are_orthons('BANG', 'BONG'); # 1
 my $idx = $orthon->index_diff('BANK', 'BARK'); # 2
 my $count = $orthon->index_identical('BANG', 'BARN'); # 2
 my (@diff) = $orthon->char_diff('BANG', 'BONG'); # (qw/A O/)
 $count = $orthon->onc(
    test => 'BANG',
    sample => [qw/BAND COCO BING RANG BONG SONG/]); # 4
 my $aref = $orthon->list_orthons(
    test => 'BANG',
    sample => [qw/BAND COCO BING RANG BONG SONG/]); # BAND, BING, RANG, BONG
 $count = $orthon->levenshtein('BANG', 'BARN'); # 2
 my $float = $orthon->old(
    test => 'BANG',
    sample => [qw/BAND COCO BING RANG BONG SONG/]); # ~= 1.67

=head1 DESCRIPTION

Lingua-Orthon provides measures of similarity of character strings based on their orthographic identity, as relevant to psycholinguistic research. Case- and mark-sensitivity for determining character equality can be controlled. Wraps to Levenshtein Distance methods, extended to the OLD-20 metric, are provided for convenience of comparison. No methods are explicitly exported; all methods are called in the object-oriented way.

=head1 SUBROUTINES/METHODS

=head2 new

 my $ortho = Lingua::Orthon->new();

Constructs/returns class object for accessing other methods.

Optionally, set the argument B<match_level> to an integer value ranging from 0 to 3 to control case- and mark-sensitivity. See L<set_eq|Lingua::Orthon/set_eq>.

=cut

sub new {
    my ( $class, %args ) = @_;
    my $self = {};
    bless $self, $class;
    $self->set_eq( match_level => $args{'match_level'} );
    return $self;
}

=head2 are_orthons

 $bool = $orthon->are_orthons('String1', 'String2');

Returns 0 or 1 (Coltheart's Boolean) if two given strings are orthographic neighbours by a 1-mismatch I<substitution>: i.e., the strings are of the same size (are equal in character count) and there is only one discrepancy between them by a single substitution of a character in the same ordinal position (no additions, deletions or transpositions). So I<BANG> and I<BAND> are orthons by this measure (they differ only in the final letter), but I<BANG> and I<BRANG> are not (the letter I<R> is an I<addition> to I<BANG> via I<BRANG>, or a I<deletion> from I<BRANG> to I<BANG>).

I<Identical strings>: If two identical letter strings are given (I<BANG>, I<BANG>), they are defined as I<not> being orthons: the number of index identical characters must be at least one less than the length of the string(s).

I<Case-sensitivity>: By default, identity is defined case-insensitively; e.g., I<Bang> and I<bang>, and I<BaNG> and I<bAnd> are orthons. However, if B<match_level> has been set (in L<new|Lingua::Orthon/new> or L<set_eq|Lingua::Orthon/set_eq>) to a higher level than 1 (or as undef or 0), then case is respected; e.g., I<Bang> and I<bang> are orthons, but I<Bang> and I<bing> are NOT orthons (they involve substituting both the I<B>s and the second letters (I<a> and I<i>) ... but I<BaNG> and I<BiNG>, or I<BaNG> and I<BING>, are orthons. (This usefully applies to putting L<Coltheart's I<N>|Lingua::Orthon/onc, coltheart_n> (the sum of single-substitution orthons a string has within a lexicon) to questions of the featural versus lexical basis of neighbourhood effects).

See Coltheart et al. (1977) (in L<REFERENCES|Lingua::Orthon/REFERENCES>). The measure is computationally simple and economical, relative to other measures, such as based on a wider array of edit-types (e.g., Levenshtein Distance), that, while having greater explanatory power (Yarkoni et al., 2008), can tax resources on the order of days to effectively compute for a single string relative to a humanly memorable corpus.

=cut

sub are_orthons {
    my ( $self, $w1, $w2 ) = @_;
    return _are_orthons( $w1, $w2, $self->{'_EQ'} );
}

=head2 index_identical

 $count = $orthon->index_identical('String1', 'String2');

Returns a count: the number of letters that are identical and in the same serial position among two given letter-strings.

For example, given I<BANG> and I<BARN>, 2 is returned for the two index-identical letters, I<B> and I<A>; I<N> is in both strings, but it is ignored as it is the third letter in I<BANG> but the fourth letter in I<BARN>, and so not in the same serial position across the two words.

=cut

sub index_identical {
    my ( $self, $w1, $w2 ) = @_;
    return _index_identical( $w1, $w2, $self->{'_EQ'} );
}

=head2 index_diff

 $posint = $orthon->index_diff('String1', 'String2');

Assuming the two strings are single-substitution orthons, returns the single index (anchored at zero) at which their letters differ.  So if the two strings are "bring" and "being", the returned value is 1.

=cut

sub index_diff {
    my ( $self, $w1, $w2 ) = @_;
    my $idx = 0;
    for my $i ( 0 .. _smallest_len( $w1, $w2 ) - 1 ) {
        if ( not $self->{'_EQ'}->( map { substr $_, $i, 1 } ( $w1, $w2 ) ) ) {
            $idx = $i;
            last;
        }
    }
    return $idx;
}

=head2 char_diff

 @ari = $orthon->char_diff('String1', 'String2');

Returns a list of the first two characters (letters) that, reading from left to right, differ between two given strings. If the strings are single-substitution orthons, these are the characters that make them so. So if the two strings are "bring" and "being", the returned list is ('r', 'e') - the order of these characters in the returned list respecting the order of the given strings. The search across the strings terminates as soon there is a mismatch; otherwise, it continues only for as long as the length of the shortest string.

The identity match (or mismatch) is sensitive to the setting of the equality function per case and marks; see L<set_eq|Lingua::Orthon/set_eq>.

=cut

sub char_diff {
    my ( $self, $w1, $w2 ) = @_;
    my @ds = ();
    for my $i ( 0 .. _smallest_len( $w1, $w2 ) - 1 ) {
        my @tmp = map { substr $_, $i, 1 } ( $w1, $w2 );
        if ( not $self->{'_EQ'}->(@tmp) ) {
            @ds = @tmp;
            last;
        }
    }
    return @ds;
}

=head2 onc, coltheart_n

 $int = $orthon->onc(test => CHARSTR, sample => AREF); 

Returns the I<orthographic neighbourhood count> (ONC), a.k.a. Coltheart's I<N>: the number of single-letter substitution orthons a particular string has with respect to a list of strings (or "lexicon") (Coltheart et al., 1977). So I<bat> has two orthons (I<bad> and I<cat>) in the list (I<bad>, I<bed>, I<cat> and I<day>).

=cut

sub onc {
    my ( $self, %args ) = @_;
    my $test_str =
      hascontent( $args{'test'} )
      ? $args{'test'}
      : croak 'Need a single character string to test for orthons';
    my $sample_aref =
      ref $args{'sample'}
      ? $args{'sample'}
      : croak
      'Need a list (aref) of character-strings to sample for orthon listing';
    my $count = 0;
    for ( 0 .. ( scalar @{$sample_aref} - 1 ) ) {
        if ( _are_orthons( $test_str, $sample_aref->[$_], $self->{'_EQ'} ) ) {
            $count++;
        }
    }
    return $count;
}
*coltheart_n = \&index_indentical;

=head2 list_orthons

 $aref = $orthon->list_orthons(test => CHARSTR, sample => AREF);
 
Returns a reference to an array of single-substitution orthographic neighbours of a given B<test> character-string that are among a given list of B<sample> character-strings. The referenced is to an empty array if no orthons are found. The order of items in the returned array follows that in which they appear in the B<sample>.

=cut

sub list_orthons {
    my ( $self, %args ) = @_;
    my $test_str =
      hascontent( $args{'test'} )
      ? $args{'test'}
      : croak 'Need a single character string to test for orthons';
    my $sample_aref =
      ref $args{'sample'}
      ? $args{'sample'}
      : croak
      'Need a list (aref) of character-strings to sample for orthon listing';
    my @orthon_list = ();
    for ( 0 .. ( scalar @{$sample_aref} - 1 ) ) {
        if ( _are_orthons( $test_str, $sample_aref->[$_], $self->{'_EQ'} ) ) {
            push @orthon_list, $sample_aref->[$_];
        }
    }
    return \@orthon_list;
}

=head2 ldist, levenshtein

 $count = $orthon->ldist('String1', 'String2'); # minimal, strings will be lower-cased

Returns the Levenshtein Distance between two given letter strings, wrapping to various Perl module's that more or less implement the Levenshtein algorithm for efficiency and case-sensitivity. Specifically, if the match level has been set at 1 (to ignore case and diacritics), the method uses L<Text::Levenshtein::distance|Text::Levenshtein/distance> (which offers "ignoring diacritics"); otherwise, it uses L<Text::Levenshtein::XS::distance|Text::Levenshtein::XS/distance> to ignore case but not marks (given present limitations of this module). The required case- and mark-sensitivity are set in the L<new|Lingua::Orthon/new> or L<set_eq|Lingua::Orthon/set_eq> methods. By default, the match is made case- and mark-I<in>sensitively (by canned Perl L<eq|perlfunc/eq>).

=cut

sub ldist {
    my ( $self, $w1, $w2 ) = @_;
    my $ldist;
    if ( $self->{'_MATCH_LEVEL'} == 1 ) {
        require Text::Levenshtein;
        $ldist =
          Text::Levenshtein::distance( $w1, $w2, { ignore_diacritics => 1 } )
          ;    # also ignores case
    }
    else {
        require Text::Levenshtein::XS;
        if ( $self->{'_MATCH_LEVEL'} == 2 ) {
            ( $w1, $w2 ) = map { lc } ( $w1, $w2 );  # ignore case but not marks
        }
        $ldist = Text::Levenshtein::XS::distance( $w1, $w2 )
          ;    # ignores nothing on its own
    }
    return $ldist;
}

=head2 old

 $mean = $orthon->old(test => CHARSTR, sample => AREF, lim => INT);

Returns the mean orthographic Levenshtein distance (OLD) of the smallest B<lim> such edit distances for a given B<test> string to all the strings in a B<sample> list. Based on Yarkoni et al. (2008), where, with the value of B<lim> is set to 20, the measure substantially contributes to prediction of performance in word recognition tasks. Here, if B<lim> is not defined, not numeric, or greater than the size of the B<sample>, then it is set by default to the size of the sample.

Levenshtein distance is calculated per the method L<ldist|Lingua::Orthon/ldist>, wrapping to external modules with respect to the conditions of string equality set in L<new|Lingua::Orthon/new> or L<set_eq|Lingua::Orthon/set_eq>. Different settings lead to different speed of calculation. The slowest calculation (by far) occurs if B<match_level> => 1 so that case- and mark-insensitive matching occurs; this relies on the pure Perl implementation in Text::Levenshtein with its argument B<ignore_diacritics> => 1. The fastest calculation (the default) occurs by setting B<match_level> => 3, when exact characters are matched, e.g., I<B> in the test-string and I<b> in a sample-string at the same index across them are taken as unequal and so will count as a substitution. This relies on the C-implementation in Text::Levenshtein::XS. Ignore case but not marks with B<match_level> => 2.

=cut

sub old {
    my ( $self, %args ) = @_;
    my $test_str =
      hascontent( $args{'test'} )
      ? $args{'test'}
      : croak 'Need a single character string to calculate OLD';
    my $sample_aref =
      ref $args{'sample'}
      ? $args{'sample'}
      : croak 'Need a list (aref) of character-strings to calculate OLD';
    my @ldists = ();
    for ( 0 .. ( scalar @{$sample_aref} - 1 ) ) {
        push @ldists, $self->ldist( $test_str, $sample_aref->[$_] );
    }
    my $lim =
      ( is_numeric( $args{'lim'} ) and $args{'lim'} <= scalar @ldists )
      ? $args{'lim'}
      : scalar @ldists;
    return mean( ( sort { $a <=> $b } @ldists )[ 0 .. int $lim - 1 ] )
      ;    # mean of first/smallest $lim-th values
}

=head2 set_eq

 $orthon->set_eq(match_level => INT); # undef, 0, 1, 2 or 3

Sets the string-matching level used in the above methods. This is called implicitly in L<new|Lingua::Orthon/new> when given a B<match_level>, or with the default value of 0. This is adopted and slightly adapted from how L<Text::Levenshtein|Text::Levenshtein> controls for case/diacritic-sensitive matching.

=over 4

=item match_level = undef, 0

Match with respect to case and diacritics: same as B<3> but simply by Perl's eq. So, e.g., I<éclair> and I<eclair> would be taken as non-identical, just as would I<Eclair> and I<eclair>.

This is the fastest option. The higher levels, as follow, use the C<eq>() function in L<Unicode::Collate|Unicode::Collate>.

=item match_level = 1

Match ignoring case and diacritics: I<ber> to I<BéZ> involves 1 edit (from I<r> to I<Z> only)
 
=item match_level = 2

Match ignoring case but respect diacritics: "ber" to "BéZ" involves 2 edits (the "er" to "éZ") 

=item match_level = 3

Match with respect to case and diacritics: "ber" to "BéZ" involves 3 edits (of all its letters)

=back

So, for example, if the test string is "abbé", it could be picked up as having the single-substitution orthographic neighbour "able" if the match level is 1, but not if it is 0, 2 or 3.

=cut

sub set_eq {
    my ( $self, %args ) = @_;
    my $match_level_arg = $args{'match_level'};
    if ( nocontent($match_level_arg) or $match_level_arg == 0 ) {
        $self->{'_MATCH_LEVEL'} = 0;
        $self->{'_EQ'} = sub { return $_[0] eq $_[1] };
    }
    elsif ( any { $match_level_arg == $_ } ( 1 .. 3 ) ) {
        $self->{'_MATCH_LEVEL'} = $match_level_arg;
        my $collator = Unicode::Collate->new(
            normalization => undef,
            level         => $match_level_arg
        );
        $self->{'_EQ'} = sub {
            return $collator->eq(@_);
        };
    }
    else {
        croak "Invalid value '$match_level_arg' given as a match level";
    }
    return;
}

# private methods

sub _smallest_len {
    my @strs = @_;
    return ( sort { $a <=> $b } map { length } @strs )[0];
}

sub _are_orthons {
    my ( $w1, $w2, $eq_fn ) = @_;
    return 0 if length $w1 != length $w2;
    return _index_identical( $w1, $w2, $eq_fn ) == ( length $w1 ) - 1;
}

sub _index_identical {
    my ( $w1, $w2, $eq_fn ) = @_;
    my $count = 0;
    for my $i ( 0 .. _smallest_len( $w1, $w2 ) - 1 ) {
        if ( $eq_fn->( map { substr $_, $i, 1 } ( $w1, $w2 ) ) ) {
            $count++;
        }
    }
    return $count;
}

=head1 DIAGNOSTICS

=over 4

=item Invalid value '...' given as a match level

Argument B<match_level> in new() or set_eq() needs to be an integer in range 0 .. 3, or undefined.

=item Need a single character string to test for orthons

Argument B<test> for calculating ONC and OLD, and listing orthons, needs to be defined and not empty.

=item Need a single character string to test for orthons

Argument B<sample> should reference an array of character-strings when calculating ONC and OLD, and listing orthons.

=back

=head1 REFERENCES

Coltheart, M., Davelaar, E., Jonasson, J. T., & Besner, D. (1977). Access to the internal lexicon. In S. Dornic (Ed.), I<Attention and performance> (Vol. 6, pp. 535-555). London, UK: Academic.

Yarkoni, T., Balota, D. A., & Yap, M. (2008). Moving beyond Coltheart's I<N>: A new measure of orthographic similarity. I<Psychonomic Bulletin and Review>, I<15>, 971-979. doi: L<10.3758/PBR.15.5.971|http://dx.doi.org/10.3758/PBR.15.5.971>.

=head1 DEPENDENCIES

L<List::AllUtils|List::AllUtils>

L<Number::Misc|Number::Misc>

L<Statistics::Lite|Statistics::Lite>

L<String::Util|String::Util>

L<Text::Levenshtein|Text::Levenshtein>

L<Text::Levenshtein::XS|Text::Levenshtein::XS>

L<Unicode::Collate|Unicode::Collate>

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 SEE ALSO

L<String::LCSS_XS|String::LCSS_XS>

L<String::Similarity|String::Similarity>

L<Text::Abbrev|Text::Abbrev>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-Lingua-Orthon-0.03 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-Orthon-0.03>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::Orthon

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-Orthon-0.03>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-Orthon-0.03>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-Orthon-0.03>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-Orthon-0.03/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2018 Roderick Garton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;    # End of Lingua::Orthon
