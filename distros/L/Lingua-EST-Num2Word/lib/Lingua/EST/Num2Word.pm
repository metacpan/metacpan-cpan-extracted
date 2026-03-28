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
our $VERSION = '0.2603270';

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


# {{{ capabilities              declare supported features

sub capabilities {
    return {
        cardinal => 1,
        ordinal  => 0,
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

version 0.2603270

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

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2est_cardinal

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
