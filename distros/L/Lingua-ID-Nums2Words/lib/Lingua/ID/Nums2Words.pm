package Lingua::ID::Nums2Words;

our $DATE = '2015-09-03'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(nums2words nums2words_simple);

our %SPEC;

use vars qw(
    $Dec_char
    $Neg_word
    $Dec_word
    $Exp_word
    $Zero_word
    %Digit_words
    %Mult_words
);

$Dec_char  = ".";
$Neg_word  = "negatif";
$Dec_word  = "koma";
$Exp_word  = "dikali sepuluh pangkat";
$Zero_word = "nol";

%Digit_words = (
    0 => $Zero_word,
    1 => 'satu',
    2 => 'dua',
    3 => 'tiga',
    4 => 'empat',
    5 => 'lima',
    6 => 'enam',
    7 => 'tujuh',
    8 => 'delapan',
    9 => 'sembilan'
);

%Mult_words = (
    0 => '',
    1 => 'ribu',
    2 => 'juta',
    3 => 'milyar',
    4 => 'triliun'
);

$SPEC{nums2words} = {
    v => 1.1,
    summary => 'Convert number to Indonesian verbage',
    description => <<'_',

This is akin to converting 123 to "a hundred and twenty three" in English.
Currently can handle real numbers in normal and scientific form in the order of
hundreds of trillions. It also preserves formatting in the number string (e.g,
given "1.00" `nums2words` will pronounce the zeros.

_
    args => {
        num => {
            schema => 'str*',
            summary => 'The number to convert',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result_naked => 1,
};
sub nums2words($) { _join_it(_handle_scinotation(@_)) }

$SPEC{nums2words_simple} = {
    v => 1.1,
    summary => 'Like nums2words but only pronounce the digits',
    description => <<'_',

This is akin to converting 123 to "one two three" in English.

_
    args => {
        num => {
            schema => 'str*',
            summary => 'The number to convert',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result_naked => 1,
};
sub nums2words_simple($) { _join_it(_handle_dec(@_)) }

sub _handle_scinotation($) {
    my $num = shift;
    my @words;

    $num =~ /^(.+)[Ee](.+)$/ and
    @words = (_handle_neg_dec($1), $Exp_word, _handle_neg_dec($2)) or
    @words = _handle_neg_dec($num);

    @words;
}

sub _handle_neg_dec($) {
    my $num = shift;
    my $is_neg;
    my @words = ();

    $num < 0 and $is_neg++;
    $num =~ s/^[\s\t]*[+-]*(.*)/$1/;

    $num =~ /^(.+)\Q$Dec_char\E(.+)$/o and
    @words = (_handle_int($1), $Dec_word, _handle_dec($2)) or

    $num =~ /^\Q$Dec_char\E(.+)$/o and
    @words = ($Digit_words{0}, $Dec_word, _handle_dec($1)) or

    $num =~ /^(.+)(?:\Q$Dec_char\E)?$/o and
    @words = _handle_int($1);

    $is_neg and
        unshift @words, $Neg_word;

    @words;
}

# handle digits before decimal
sub _handle_int($) {
    my $num = shift;
    my @words = ();
    my $order = 0;
    my $t;

    while($num =~ /^(.*?)([\d\D*]{1,3})$/) {
        $num = $1;
        ($t = $2) =~ s/\D//g;
        unshift @words, $Mult_words{$order} if $t > 0;
        unshift @words, _handle_thousand($t, $order);
        $order++;
    }

    @words = ($Zero_word) if not join('',@words)=~/\S/;
    @words;
}

sub _handle_thousand($$) {
    my $num = shift;
    my $order = shift;
    my @words = ();

    my $n1 = $num % 10;
    my $n2 = ($num % 100 - $n1) / 10;
    my $n3 = ($num - $n2*10 - $n1) / 100;

    $n3 == 0 && $n2 == 0 && $n1 > 0 and (
        $n1 == 1 && $order == 1 and @words = ("se") or
        @words = ($Digit_words{$n1}) );

    $n3 == 1 and @words = ("seratus") or
    $n3 >  1 and @words = ($Digit_words{$n3}, "ratus");

    $n2 == 1 and (
        $n1 == 0 and push(@words, "sepuluh") or
        $n1 == 1 and push(@words, "sebelas") or
        push(@words, $Digit_words{$n1}, "belas")
    );

    $n2 > 1 and do {
        push @words, $Digit_words{$n2}, "puluh";
        push @words, $Digit_words{$n1} if $n1 > 0;
    };

    $n3 > 0 && $n2 == 0 && $n1 > 0 and
    push @words, $Digit_words{$n1};

    $n3 != 0 || $n2 != 0 || $n1 != 0 and
    @words;
}

# handle digits after decimal
sub _handle_dec($) {
    my $num = shift;
    my @words = ();
    my $i;
    my $t;

    for( $i=0; $i<=length($num)-1; $i++ ) {
        $t = substr($num, $i, 1);
        exists $Digit_words{$t} and
        push @words, $Digit_words{$t};
    }

    @words = ($Zero_word) if not join('',@words)=~/\S/;
    @words;
}

# join array of words, also join (se, ratus) -> seratus, etc.
sub _join_it(@) {
    my $words = '';
    my $w;

    while(defined( $w = shift )) {
        $words .= $w;
        $words .= ' ' unless not length $w or $w eq 'se' or not @_;
    }
    $words =~ s/^\s+//;
    $words =~ s/\s+$//;
    $words;
}

1;
# ABSTRACT: Convert number to Indonesian verbage

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::ID::Nums2Words - Convert number to Indonesian verbage

=head1 VERSION

This document describes version 0.04 of Lingua::ID::Nums2Words (from Perl distribution Lingua-ID-Nums2Words), released on 2015-09-03.

=head1 SYNOPSIS

 use Lingua::ID::Nums2Words qw(nums2words nums2words_simple);

 print nums2words(123);        # seratus dua puluh tiga
 print nums2words_simple(123); # satu dua tiga

=head1 DESCRIPTION

This module provides two functions, B<nums2words> and B<nums2words_simple>, to
convert number to Indonesian verbage. Popular Indonesian term for this kind of
library is "terbilang", or roughly "spelled amount" in English.

=head1 FUNCTIONS


=head2 nums2words($num) -> any

Convert number to Indonesian verbage.

This is akin to converting 123 to "a hundred and twenty three" in English.
Currently can handle real numbers in normal and scientific form in the order of
hundreds of trillions. It also preserves formatting in the number string (e.g,
given "1.00" C<nums2words> will pronounce the zeros.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num>* => I<str>

The number to convert.

=back

Return value:  (any)


=head2 nums2words_simple($num) -> any

Like nums2words but only pronounce the digits.

This is akin to converting 123 to "one two three" in English.

Arguments ('*' denotes required arguments):

=over 4

=item * B<num>* => I<str>

The number to convert.

=back

Return value:  (any)

=head1 SEE ALSO

L<Lingua::ID::Words2Nums>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Lingua-ID-Nums2Words>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Lingua-ID-Nums2Words>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Lingua-ID-Nums2Words>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
