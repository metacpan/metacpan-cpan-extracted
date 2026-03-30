# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::KAZ::Num2Word;
# ABSTRACT: Number to word conversion in Kazakh

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
our $VERSION = '0.2603300';

# }}}

# {{{ num2kaz_cardinal                 convert number to text

sub num2kaz_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    my @ones = ('нөл', 'бір', 'екі', 'үш', 'төрт', 'бес', 'алты', 'жеті', 'сегіз', 'тоғыз');
    my @tens = ('он', 'жиырма', 'отыз', 'қырық', 'елу', 'алпыс', 'жетпіс', 'сексен', 'тоқсан');

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
        $out = 'жүз';
    }
    elsif ($positive > 100 && $positive < 1000) {                # 101 .. 999
        my $hun_idx = int($positive / 100);
        $remain     = $positive % 100;

        $out  = $hun_idx == 1 ? 'жүз' : $ones[$hun_idx] . ' жүз';
        $out .= $remain ? ' ' . num2kaz_cardinal($remain) : '';
    }
    elsif ($positive >= 1000 && $positive < 1_000_000) {         # 1000 .. 999_999
        my $tho_idx = int($positive / 1000);
        $remain     = $positive % 1000;

        $out  = $tho_idx == 1 ? 'мың' : num2kaz_cardinal($tho_idx) . ' мың';
        $out .= $remain ? ' ' . num2kaz_cardinal($remain) : '';
    }
    elsif ($positive >= 1_000_000 && $positive < 1_000_000_000) { # 1_000_000 .. 999_999_999
        my $mil_idx = int($positive / 1_000_000);
        $remain     = $positive % 1_000_000;

        $out  = num2kaz_cardinal($mil_idx) . ' миллион';
        $out .= $remain ? ' ' . num2kaz_cardinal($remain) : '';
    }

    return $out;
}

# }}}

# {{{ num2kaz_ordinal                 convert number to ordinal text

sub num2kaz_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [1, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 1
           || $number > 999_999_999;

    my $cardinal = num2kaz_cardinal($number);

    # Kazakh ordinals: cardinal + suffix determined by vowel harmony.
    # Cyrillic vowels: а, е, ә, і, о, ө, ұ, ү, ы
    # After consonant: -(ы)ншы / -(і)нші / -(ұ)ншы / -(ү)нші
    # After vowel:     -ншы    / -нші    / -ншы    / -нші

    my $last_vowel = q{};
    if ($cardinal =~ m{([аеәіоөұүы])[^аеәіоөұүы]*\z}xms) {
        $last_vowel = $1;
    }

    my $ends_in_vowel = $cardinal =~ m{[аеәіоөұүы]\z}xms;

    my %suffix_v = (   # after vowel
        'а' => 'ншы',  'ы' => 'ншы',
        'о' => 'ншы',  'ұ' => 'ншы',
        'е' => 'нші',  'і' => 'нші',
        'ә' => 'нші',  'ө' => 'нші',  'ү' => 'нші',
    );
    my %suffix_c = (   # after consonant
        'а' => 'ыншы', 'ы' => 'ыншы',
        'о' => 'ыншы', 'ұ' => 'ыншы',
        'е' => 'інші',  'і' => 'інші',
        'ә' => 'інші',  'ө' => 'інші',  'ү' => 'інші',
    );

    my $suffix_table = $ends_in_vowel ? \%suffix_v : \%suffix_c;
    my $suffix = $suffix_table->{$last_vowel} // 'інші';

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

Lingua::KAZ::Num2Word - Number to word conversion in Kazakh


=head1 VERSION

version 0.2603300

Lingua::KAZ::Num2Word is module for converting numbers into their written
representation in Kazakh. Converts whole numbers from 0 up to 999 999 999.

Text is encoded in UTF-8 (Cyrillic script).

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::KAZ::Num2Word;

 my $text = Lingua::KAZ::Num2Word::num2kaz_cardinal( 123 );

 print $text || "sorry, can't convert this number into kazakh language.";

 my $ord = Lingua::KAZ::Num2Word::num2kaz_ordinal( 3 );
 print $ord;    # "үшінші"

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2kaz_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to text representation.
Only numbers from interval [0, 999_999_999] will be converted.

=item B<num2kaz_ordinal> (positional)

  1   num    number to convert
  =>  str    converted ordinal string

Convert number to ordinal text representation using Kazakh vowel harmony.
Only numbers from interval [1, 999_999_999] will be converted.

=item B<capabilities> (void)

  =>  hashref    hash of supported features

Returns a hash reference indicating which conversion features are supported.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2kaz_cardinal

=item num2kaz_ordinal

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
