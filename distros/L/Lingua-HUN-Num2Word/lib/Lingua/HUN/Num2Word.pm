# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::HUN::Num2Word;
# ABSTRACT: Number to word conversion in Hungarian

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
our $VERSION = '0.2603260';

# }}}

# {{{ num2hun_cardinal                 convert number to text

sub num2hun_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    my @ones = qw(nulla egy kettő három négy öt hat hét nyolc kilenc);
    my @tens = qw(tíz húsz harminc negyven ötven hatvan hetven nyolcvan kilencven);

    # 0 .. 9
    return $ones[$positive] if $positive < 10;

    # 10 .. 19
    if ($positive >= 10 && $positive < 20) {
        return 'tíz' if $positive == 10;
        return 'tizen' . $ones[$positive - 10];
    }

    # 20 .. 29
    if ($positive >= 20 && $positive < 30) {
        return 'húsz' if $positive == 20;
        return 'huszon' . $ones[$positive - 20];
    }

    # 30 .. 99
    if ($positive >= 30 && $positive < 100) {
        my $ten_idx = int($positive / 10);
        my $remain  = $positive % 10;

        my $out = $tens[$ten_idx - 1];
        $out .= $ones[$remain] if $remain;
        return $out;
    }

    my $out;
    my $idx;
    my $remain;

    # 100 .. 999
    if ($positive >= 100 && $positive < 1000) {
        $idx    = int($positive / 100);
        $remain = $positive % 100;

        $out  = $idx == 1 ? 'száz' : _compound_cardinal($idx) . 'száz';
        $out .= $remain ? num2hun_cardinal($remain) : '';
    }
    # 1000 .. 999_999
    elsif ($positive >= 1000 && $positive < 1_000_000) {
        $idx    = int($positive / 1000);
        $remain = $positive % 1000;

        $out  = $idx == 1 ? 'ezer' : _compound_cardinal($idx) . 'ezer';
        $out .= $remain ? num2hun_cardinal($remain) : '';
    }
    # 1_000_000 .. 999_999_999
    elsif ($positive >= 1_000_000 && $positive < 1_000_000_000) {
        $idx    = int($positive / 1_000_000);
        $remain = $positive % 1_000_000;

        $out  = _compound_cardinal($idx) . 'millió';
        $out .= $remain ? '-' . num2hun_cardinal($remain) : '';
    }

    return $out;
}

# }}}
# {{{ _compound_cardinal               cardinal form using két instead of kettő

sub _compound_cardinal {
    my $positive = shift;

    my $text = num2hun_cardinal($positive);
    $text =~ s{kettő}{két}gxms;

    return $text;
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::HUN::Num2Word - Number to word conversion in Hungarian


=head1 VERSION

version 0.2603260

Lingua::HUN::Num2Word is a module for converting numbers into their written
representation in Hungarian. Converts whole numbers from 0 up to 999 999 999.

Text output is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::HUN::Num2Word;

 my $text = Lingua::HUN::Num2Word::num2hun_cardinal( 123 );

 print $text || "sorry, can't convert this number into Hungarian.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2hun_cardinal> (positional)

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

=item num2hun_cardinal

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
