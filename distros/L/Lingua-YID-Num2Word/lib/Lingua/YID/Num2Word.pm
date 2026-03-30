# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::YID::Num2Word;
# ABSTRACT: Number to word conversion in Yiddish

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

# {{{ num2yid_cardinal                 convert number to text

sub num2yid_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    my @tokens1 = qw(נול אײנס צװײ דרײַ פֿיר פֿינף זעקס זיבן אכט נײַן צען עלף צוועלף);
    my @tokens2 = qw(צוואַנציק דרײַסיק פערציק פופציק זעכציק זיבעציק אַכציק נײַנציק הונדערט);

    return $tokens1[$positive]               if ($positive >= 0 && $positive < 13); # 0 .. 12
    return 'פערצן'                            if ($positive == 14);                  # YIVO: fertsn
    return 'פופצן'                            if ($positive == 15);                  # YIVO: fuftsn
    return 'זעכצן'                            if ($positive == 16);                  # YIVO: zekhtsn
    return 'זיבעצן'                           if ($positive == 17);                  # YIVO: zibetsn
    return 'אַכצן'                            if ($positive == 18);                  # YIVO: akhtsn
    return 'נײַנצן'                           if ($positive == 19);                  # YIVO: nayntsn
    return $tokens1[$positive-10] . 'צן'      if ($positive == 13);                  # draytsn

    my $out;          # string for return value construction
    my $one_idx;      # index for tokens1 array
    my $remain;       # remainder

    if ($positive > 19 && $positive < 101) {              # 20 .. 100
        $one_idx = int ($positive / 10);
        $remain  = $positive % 10;

        $out  = "$tokens1[$remain] און " if ($remain);
        $out .= $tokens2[$one_idx - 2];
    }
    elsif ($positive > 100 && $positive < 1000) {       # 101 .. 999
        $one_idx = int ($positive / 100);
        $remain  = $positive % 100;

        $out  = "$tokens1[$one_idx] הונדערט";
        $out .= $remain ? ' ' . num2yid_cardinal($remain) : '';
    }
    elsif ($positive > 999 && $positive < 1_000_000) {  # 1000 .. 999_999
        $one_idx = int ($positive / 1000);
        $remain  = $positive % 1000;

        $out  = num2yid_cardinal($one_idx) . ' טויזנט';
        $out .= $remain ? ' ' . num2yid_cardinal($remain) : '';
    }
    elsif (   $positive > 999_999
           && $positive < 1_000_000_000) {                 # 1_000_000 .. 999_999_999
        $one_idx = int ($positive / 1000000);
        $remain  = $positive % 1000000;

        $out  = num2yid_cardinal($one_idx) . ' מיליאָן';
        $out .= $remain ? ' ' . num2yid_cardinal($remain) : '';
    }

    return $out;
}

# }}}

# {{{ num2yid_ordinal                  convert number to ordinal text

sub num2yid_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [1, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 1
           || $number > 999_999_999;

    # Fully irregular forms (masculine nominative with -er suffix)
    return 'ערשטער'   if $number == 1;   # ershter
    return 'צווייטער' if $number == 2;   # tsveyter
    return 'דריטער'   if $number == 3;   # driter

    # Stem irregulars
    return 'זיבעטער'  if $number == 7;   # zibeter
    return 'אַכטער'   if $number == 8;   # akhter

    my $cardinal = num2yid_cardinal($number);

    # Numbers 4-19 get suffix "טער", 20+ get "סטער"
    my $suffix = $number < 20 ? 'טער' : 'סטער';

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

Lingua::YID::Num2Word - Number to word conversion in Yiddish

=head1 VERSION

version 0.2603300

Lingua::YID::Num2Word is a module for converting numbers into their written
representation in Yiddish (Hebrew script). Converts whole numbers from 0 up
to 999 999 999.

Orthography follows the YIVO standard (Yidisher Visnshaftlekher Institut).
Text is encoded in UTF-8 (Hebrew script).

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::YID::Num2Word;

 my $text = Lingua::YID::Num2Word::num2yid_cardinal( 123 );
 print $text || "sorry, can't convert this number into Yiddish.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2yid_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to Yiddish text representation (Hebrew script).
Only numbers from interval [0, 999_999_999] will be converted.

=item B<num2yid_ordinal> (positional)

  1   num    number to convert
  =>  str    converted ordinal string (Hebrew script)

Convert number to its Yiddish ordinal text representation.
Only numbers from interval [1, 999_999_999] will be converted.
Handles irregular forms and applies correct suffixes.

=item B<capabilities> (void)

  =>  hashref    hash of supported conversion types

Returns a hashref indicating which conversion types this module supports.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2yid_cardinal

=item num2yid_ordinal

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
