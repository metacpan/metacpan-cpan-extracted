# For Emacs: -*- mode:cperl; eval: (folding-mode 1); -*-

package Lingua::SWE::Num2Word;
# ABSTRACT: Number to word conversion in Swedish

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;

# }}}
# {{{ variables declaration
our $VERSION = '0.2603270';

# }}}
# {{{ num2sv_cardinal                 convert number to text

sub num2sv_cardinal :Export {
  my $positive = shift // return 'noll';

  return if ($positive < 0);

  my $out;
  my @tokens1  = qw(noll ett två tre fyra fem sex sju åtta nio tio elva
                    tolv tretton fjorton femton sexton sjutton arton nitton);   # 0-19 Cardinals
  my @tokens2  = qw(tjugo trettio fyrtio femtio sextio sjutio åttio nittio);    # 20-90 Cardinals (end with zero)

  return $tokens1[$positive] if($positive < 20);            # interval  0 - 19

  if($positive < 100) {                                     # interval 20 - 99
    my @num = split '',$positive;

    $out  = $tokens2[$num[0]-2];
    $out .= $tokens1[$num[1]] if ($num[1]);
  } elsif($positive < 1000) {                               # interval 100 - 999
    my @num = split '',$positive;

    $out = $tokens1[$num[0]].'hundra';

    if ((int $num[1].$num[2]) < 20 && (int $num[1].$num[2])>0 ) {
      $out .= &num2sv_cardinal(int $num[1].$num[2]);
    } else {
      $out .= $tokens2[$num[1]-2] if($num[1]);
      $out .= $tokens1[$num[2]]   if($num[2]);
    }
  } elsif($positive < 1000_000) {                           # interval 1000 - 999_999
    my @num = split '',$positive;
    my @sub = splice @num,-3;

    $out  = &num2sv_cardinal(int join '',@num);
    $out .= 'tusen';
    $out .= &num2sv_cardinal(int join '',@sub) if (int(join "",@sub) >0);
  } elsif($positive < 1_000_000_000) {                      # interval 1_000_000 - 999_999_999
    my @num = split '',$positive;
    my @sub = splice @num,-6;

    $out  = &num2sv_cardinal(int join '',@num);
    $out .= ' miljoner ';
    $out .= &num2sv_cardinal(int join '',@sub) if (int(join "",@sub) >0);
  }

  return $out;
}

# }}}

# {{{ num2sv_ordinal                  convert number to ordinal text

sub num2sv_ordinal :Export {
    my $number = shift;

    return if !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 1
           || $number > 999_999_999;

    # Fully irregular 1-3
    return 'första' if $number == 1;
    return 'andra'  if $number == 2;
    return 'tredje' if $number == 3;

    # Irregular 4-12
    my %irregular = (
         4 => 'fjärde',
         5 => 'femte',
         6 => 'sjätte',
         7 => 'sjunde',
         8 => 'åttonde',
         9 => 'nionde',
        10 => 'tionde',
        11 => 'elfte',
        12 => 'tolfte',
    );
    return $irregular{$number} if exists $irregular{$number};

    # 13-19: special ordinal stems
    my %teens = (
        13 => 'trettonde',
        14 => 'fjortonde',
        15 => 'femtonde',
        16 => 'sextonde',
        17 => 'sjuttonde',
        18 => 'artonde',
        19 => 'nittonde',
    );
    return $teens{$number} if exists $teens{$number};

    # Tens ordinal stems (exact multiples)
    my %tens_ord = (
        20 => 'tjugonde',
        30 => 'trettionde',
        40 => 'fyrtionde',
        50 => 'femtionde',
        60 => 'sextionde',
        70 => 'sjuttionde',
        80 => 'åttionde',
        90 => 'nittionde',
    );

    # 20-99
    if ($number < 100) {
        my $tens = int($number / 10) * 10;
        my $ones = $number % 10;
        return $tens_ord{$tens} if $ones == 0;

        # Compound: cardinal tens prefix + ordinal of ones
        my @tens_card = qw(tjugo trettio fyrtio femtio sextio sjutio åttio nittio);
        return $tens_card[int($number/10) - 2] . num2sv_ordinal($ones);
    }

    # 100-999
    if ($number < 1000) {
        my $hundreds = int($number / 100);
        my $remain   = $number % 100;

        if ($remain == 0) {
            my @tokens1 = qw(noll ett två tre fyra fem sex sju åtta nio);
            return $tokens1[$hundreds] . 'hundrade';
        }
        return num2sv_cardinal(int($number / 100) * 100) . num2sv_ordinal($remain);
    }

    # 1000-999_999
    if ($number < 1_000_000) {
        my $remain = $number % 1000;
        if ($remain == 0) {
            return num2sv_cardinal(int($number / 1000)) . 'tusende';
        }
        return num2sv_cardinal(int($number / 1000)) . 'tusen' . num2sv_ordinal($remain);
    }

    # 1_000_000 - 999_999_999
    if ($number < 1_000_000_000) {
        my $remain = $number % 1_000_000;
        if ($remain == 0) {
            return num2sv_cardinal(int($number / 1_000_000)) . ' miljonte';
        }
        return num2sv_cardinal(int($number / 1_000_000)) . ' miljoner ' . num2sv_ordinal($remain);
    }

    return;
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

=head1 NAME

Lingua::SWE::Num2Word - Number to word conversion in Swedish


=head1 VERSION

version 0.2603270

Lingua::SWE::Num2Word is module for converting numbers into their representation
in Swedish. Converts whole numbers from 0 up to 999 999 999.

Output text is encoded in UTF-8 encoding.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::SWE::Num2Word;

 my $text = Lingua::SWE::Num2Word::num2sv_cardinal( 123 );
 print $text || "sorry, can't convert this number into swedish language.";

 my $ord = Lingua::SWE::Num2Word::num2sv_ordinal( 3 );
 print $ord;    # "tredje"

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2sv_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
  =>  undef  if input number is not known

Convert number to text representation.

=item B<num2sv_ordinal> (positional)

  1   num    number to convert (1 .. 999_999_999)
  =>  str    converted ordinal string
  =>  undef  if input number is out of range

Convert number to its Swedish ordinal text representation.
Handles irregular forms (första, andra, tredje, etc.)
and applies correct suffixes for regular forms.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2sv_cardinal

=item num2sv_ordinal

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

Copyright (c) PetaMem, s.r.o. 2004-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
