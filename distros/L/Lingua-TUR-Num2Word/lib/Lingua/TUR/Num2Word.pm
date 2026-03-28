# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::TUR::Num2Word;
# ABSTRACT: Number to word conversion in Turkish

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;
use Readonly;

# }}}
# {{{ variable declarations

my Readonly::Scalar $COPY = 'Copyright (c) PetaMem, s.r.o. 2002-present';
our $VERSION = '0.2603270';

# }}}

# {{{ num2tur_cardinal                 convert number to text

sub num2tur_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    my @ones = qw(sıfır bir iki üç dört beş altı yedi sekiz dokuz);
    my @tens = qw(on yirmi otuz kırk elli altmış yetmiş seksen doksan);

    return $ones[$positive]                    if ($positive >= 0 && $positive < 10);  # 0 .. 9
    return $tens[$positive / 10 - 1]           if ($positive >= 10 && $positive < 100 && $positive % 10 == 0);  # 10,20,..,90

    my $out;
    my $remain;

    if ($positive > 9 && $positive < 100) {                     # 11 .. 99
        my $ten_idx = int($positive / 10);
        $remain     = $positive % 10;

        $out = $tens[$ten_idx - 1] . ' ' . $ones[$remain];
    }
    elsif ($positive == 100) {                                   # 100
        $out = 'yüz';
    }
    elsif ($positive > 100 && $positive < 1000) {                # 101 .. 999
        my $hun_idx = int($positive / 100);
        $remain     = $positive % 100;

        $out  = $hun_idx == 1 ? 'yüz' : $ones[$hun_idx] . ' yüz';
        $out .= $remain ? ' ' . num2tur_cardinal($remain) : '';
    }
    elsif ($positive >= 1000 && $positive < 1_000_000) {         # 1000 .. 999_999
        my $tho_idx = int($positive / 1000);
        $remain     = $positive % 1000;

        $out  = $tho_idx == 1 ? 'bin' : num2tur_cardinal($tho_idx) . ' bin';
        $out .= $remain ? ' ' . num2tur_cardinal($remain) : '';
    }
    elsif ($positive >= 1_000_000 && $positive < 1_000_000_000) { # 1_000_000 .. 999_999_999
        my $mil_idx = int($positive / 1_000_000);
        $remain     = $positive % 1_000_000;

        $out  = num2tur_cardinal($mil_idx) . ' milyon';
        $out .= $remain ? ' ' . num2tur_cardinal($remain) : '';
    }

    return $out;
}

# }}}

# {{{ num2tur_ordinal                 convert number to ordinal text

sub num2tur_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [1, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 1
           || $number > 999_999_999;

    my $cardinal = num2tur_cardinal($number);

    # Turkish ordinals: cardinal + suffix determined by vowel harmony.
    # Suffix has two forms depending on whether the cardinal ends in
    # a vowel or consonant:
    #   ends in consonant: ıncı / inci / uncu / üncü
    #   ends in vowel:     ncı  / nci  / ncu  / ncü
    # Consonant softening: final "t" becomes "d" (dört -> dörd).

    $cardinal =~ s{dört\z}{dörd}xms;

    my $last_vowel = q{};
    if ($cardinal =~ m{([aeıioöuü])[^aeıioöuü]*\z}xms) {
        $last_vowel = $1;
    }

    my $ends_in_vowel = $cardinal =~ m{[aeıioöuü]\z}xms;

    my %suffix_v = (   # after vowel: drop the leading harmony vowel
        'a' => 'ncı',  'ı' => 'ncı',
        'e' => 'nci',  'i' => 'nci',
        'o' => 'ncu',  'u' => 'ncu',
        'ö' => 'ncü',  'ü' => 'ncü',
    );
    my %suffix_c = (   # after consonant: full suffix with harmony vowel
        'a' => 'ıncı', 'ı' => 'ıncı',
        'e' => 'inci',  'i' => 'inci',
        'o' => 'uncu',  'u' => 'uncu',
        'ö' => 'üncü',  'ü' => 'üncü',
    );

    my $suffix_table = $ends_in_vowel ? \%suffix_v : \%suffix_c;
    my $suffix = $suffix_table->{$last_vowel} // 'inci';

    return $cardinal . $suffix;
}

# }}}


# {{{ capabilities              declare supported features

sub capabilities {
    return {
        cardinal => 1,
        ordinal  => 1,
    };
}

# }}}
1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::TUR::Num2Word - Number to word conversion in Turkish


=head1 VERSION

version 0.2603270

Lingua::TUR::Num2Word is module for converting numbers into their written
representation in Turkish. Converts whole numbers from 0 up to 999 999 999.

Text is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::TUR::Num2Word;

 my $text = Lingua::TUR::Num2Word::num2tur_cardinal( 123 );

 print $text || "sorry, can't convert this number into turkish language.";

 my $ord = Lingua::TUR::Num2Word::num2tur_ordinal( 3 );
 print $ord;    # "üçüncü"

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2tur_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to text representation.
Only numbers from interval [0, 999_999_999] will be converted.

=item B<num2tur_ordinal> (positional)

  1   num    number to convert
  =>  str    converted ordinal string

Convert number to ordinal text representation using Turkish vowel harmony.
Only numbers from interval [1, 999_999_999] will be converted.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2tur_cardinal

=item num2tur_ordinal

=back

=cut

# }}}
# {{{ POD FOOTER

=pod

=head1 AUTHORS

 specification, maintenance:
   Richard C. Jelinek E<lt>rj@petamem.comE<gt>
 maintenance, coding (2025-present):
   PetaMem AI Coding Agents

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2002-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
