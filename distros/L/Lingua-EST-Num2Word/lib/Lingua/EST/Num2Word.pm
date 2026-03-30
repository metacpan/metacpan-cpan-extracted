# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::EST::Num2Word;
# ABSTRACT: Number to word conversion in Estonian

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

# {{{ num2est_cardinal                 convert number to text

sub num2est_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    my @ones = qw(null üks kaks kolm neli viis kuus seitse kaheksa üheksa);

    return $ones[$positive]                          if ($positive >= 0 && $positive < 10);
    return 'kümme'                                   if ($positive == 10);

    # 11-19: stem + teist
    if ($positive > 10 && $positive < 20) {
        my @teens = qw(üksteist kaksteist kolmteist neliteist viisteist
                       kuusteist seitseteist kaheksateist üheksateist);
        return $teens[$positive - 11];
    }

    my $out;
    my $remain;

    my @tens_prefix = qw(. . kaks kolm neli viis kuus seitse kaheksa üheksa);

    if ($positive > 19 && $positive < 100) {                           # 20 .. 99
        my $tens_idx = int($positive / 10);
        $remain      = $positive % 10;

        $out  = $tens_prefix[$tens_idx] . 'kümmend';
        $out .= ' ' . $ones[$remain] if ($remain);
    }
    elsif ($positive == 100) {                                         # 100
        $out = 'sada';
    }
    elsif ($positive > 100 && $positive < 1000) {                      # 101 .. 999
        my $hundreds = int($positive / 100);
        $remain      = $positive % 100;

        $out  = $hundreds == 1 ? 'sada' : $ones[$hundreds] . 'sada';
        $out .= ' ' . num2est_cardinal($remain) if ($remain);
    }
    elsif ($positive >= 1000 && $positive < 1_000_000) {               # 1000 .. 999_999
        my $thousands = int($positive / 1000);
        $remain       = $positive % 1000;

        $out  = $thousands == 1 ? 'tuhat' : num2est_cardinal($thousands) . ' tuhat';
        $out .= ' ' . num2est_cardinal($remain) if ($remain);
    }
    elsif ($positive >= 1_000_000 && $positive < 1_000_000_000) {      # 1_000_000 .. 999_999_999
        my $millions = int($positive / 1_000_000);
        $remain      = $positive % 1_000_000;

        if ($millions == 1) {
            $out = 'miljon';
        }
        else {
            $out = num2est_cardinal($millions) . ' miljonit';
        }
        $out .= ' ' . num2est_cardinal($remain) if ($remain);
    }

    return $out;
}

# }}}


# {{{ num2est_ordinal                  convert number to ordinal text

sub num2est_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [1, 999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 1
           || $number > 999_999_999;

    # 1-10: unique ordinal forms
    my %base_ordinals = (
        1  => 'esimene',
        2  => 'teine',
        3  => 'kolmas',
        4  => 'neljas',
        5  => 'viies',
        6  => 'kuues',
        7  => 'seitsmes',
        8  => 'kaheksas',
        9  => 'üheksas',
        10 => 'kümnes',
    );

    return $base_ordinals{$number} if exists $base_ordinals{$number};

    # 11-19: stem + "teistkümnes"
    if ($number >= 11 && $number <= 19) {
        my @teen_stems = qw(. ühe kahe kolme nelja viie kuue seitse kaheksa üheksa);
        return $teen_stems[$number - 10] . 'teistkümnes';
    }

    # Round tens 20-90: stem + "kümnes"
    if ($number >= 20 && $number < 100 && $number % 10 == 0) {
        my @tens_stems = qw(. . kahe kolme nelja viie kuue seitse kaheksa üheksa);
        my $tens_idx = int($number / 10);
        return $tens_stems[$tens_idx] . 'kümnes';
    }

    # Compound 21-99: cardinal tens prefix + ordinal unit
    if ($number > 20 && $number < 100) {
        my @tens_prefix = qw(. . kaks kolm neli viis kuus seitse kaheksa üheksa);
        my $tens_idx = int($number / 10);
        my $remain   = $number % 10;
        return $tens_prefix[$tens_idx] . 'kümmend ' . num2est_ordinal($remain);
    }

    # Round hundreds
    if ($number >= 100 && $number < 1000 && $number % 100 == 0) {
        my $h = int($number / 100);
        my @ones = qw(. üks kaks kolm neli viis kuus seitse kaheksa üheksa);
        my $prefix = $h == 1 ? 'sajas' : $ones[$h] . 'sajas';
        return $prefix;
    }

    # Compound hundreds
    if ($number >= 100 && $number < 1000) {
        my $h = int($number / 100);
        my $remain = $number % 100;
        my @ones = qw(. üks kaks kolm neli viis kuus seitse kaheksa üheksa);
        my $prefix = $h == 1 ? 'sada' : $ones[$h] . 'sada';
        return $prefix . ' ' . num2est_ordinal($remain);
    }

    # Round thousands
    if ($number >= 1000 && $number < 1_000_000 && $number % 1000 == 0) {
        my $t = int($number / 1000);
        my $prefix = $t == 1 ? 'tuhandes' : num2est_cardinal($t) . ' tuhandes';
        return $prefix;
    }

    # Compound thousands
    if ($number >= 1000 && $number < 1_000_000) {
        my $t = int($number / 1000);
        my $remain = $number % 1000;
        my $prefix = $t == 1 ? 'tuhat' : num2est_cardinal($t) . ' tuhat';
        return $prefix . ' ' . num2est_ordinal($remain);
    }

    # Round millions
    if ($number >= 1_000_000 && $number < 1_000_000_000 && $number % 1_000_000 == 0) {
        my $m = int($number / 1_000_000);
        if ($m == 1) {
            return 'miljones';
        }
        return num2est_cardinal($m) . ' miljones';
    }

    # Compound millions
    if ($number >= 1_000_000 && $number < 1_000_000_000) {
        my $m = int($number / 1_000_000);
        my $remain = $number % 1_000_000;
        my $prefix = $m == 1 ? 'miljon' : num2est_cardinal($m) . ' miljonit';
        return $prefix . ' ' . num2est_ordinal($remain);
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

=encoding utf-8

=head1 NAME

Lingua::EST::Num2Word - Number to word conversion in Estonian


=head1 VERSION

version 0.2603300

Lingua::EST::Num2Word is module for converting numbers into their written
representation in Estonian. Converts whole numbers from 0 up to 999 999 999.

Text is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::EST::Num2Word;

 my $text = Lingua::EST::Num2Word::num2est_cardinal( 123 );

 print $text || "sorry, can't convert this number into Estonian.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2est_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to text representation.
Only numbers from interval [0, 999_999_999] will be converted.

=item B<num2est_ordinal> (positional)

  1   num    number to convert
  =>  str    converted ordinal string

Convert number to its Estonian ordinal text representation.
Only numbers from interval [1, 999_999_999] will be converted.
Estonian ordinals use distinct stems (esimene, teine, kolmas, etc.)
rather than simple suffixing of cardinals.


=item B<capabilities> (void)

  =>  href   hashref indicating supported conversion types

Returns a hashref of capabilities for this language module.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2est_cardinal

=item num2est_ordinal

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
