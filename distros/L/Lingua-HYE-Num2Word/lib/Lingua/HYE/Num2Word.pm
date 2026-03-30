# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::HYE::Num2Word;
# ABSTRACT: Number to word conversion in Armenian

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

my @ONES = ('զրո', 'մեկ', 'երկու', 'երեք', 'չորս',
            'հինգ', 'վեց', 'յոթ', 'ութ', 'ինը');

my @TEENS = ('տասնմեկ', 'տասներկու', 'տասներեք',
             'տասնչորս', 'տասնհինգ', 'տասնվեց',
             'տասնյոթ', 'տասնութ', 'տասնինը');

my @TENS = ('', 'տաս', 'քսան', 'երեսուն', 'քառասուն',
            'հիսուն', 'վաթսուն', 'յոթանասուն', 'ութսուն', 'իննսուն');

my $HUNDRED  = 'հարյուր';
my $THOUSAND = 'հազար';
my $MILLION  = 'միլիոն';

# }}}

# {{{ num2hye_cardinal                 convert number to text

sub num2hye_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    return _convert($positive);
}

# }}}
# {{{ _convert                          internal recursive conversion

sub _convert {
    my $n = shift;

    return $ONES[$n]         if $n >= 0 && $n <= 9;
    return $TENS[1]          if $n == 10;
    return $TEENS[$n - 11]   if $n >= 11 && $n <= 19;

    my $out;

    if ($n >= 20 && $n <= 99) {
        my $ten_idx = int($n / 10);
        my $remain  = $n % 10;
        $out = $TENS[$ten_idx];
        $out .= " $ONES[$remain]" if $remain;
    }
    elsif ($n >= 100 && $n <= 999) {
        my $h      = int($n / 100);
        my $remain = $n % 100;
        $out  = $h == 1 ? $HUNDRED : "$ONES[$h] $HUNDRED";
        $out .= ' ' . _convert($remain) if $remain;
    }
    elsif ($n >= 1000 && $n <= 999_999) {
        my $k      = int($n / 1000);
        my $remain = $n % 1000;
        $out  = $k == 1 ? $THOUSAND : _convert($k) . " $THOUSAND";
        $out .= ' ' . _convert($remain) if $remain;
    }
    elsif ($n >= 1_000_000 && $n <= 999_999_999) {
        my $m      = int($n / 1_000_000);
        my $remain = $n % 1_000_000;
        $out  = $m == 1 ? "$ONES[1] $MILLION" : _convert($m) . " $MILLION";
        $out .= ' ' . _convert($remain) if $remain;
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

Lingua::HYE::Num2Word - Number to word conversion in Armenian

=head1 VERSION

version 0.2603300

Lingua::HYE::Num2Word is module for converting numbers into their written
representation in Armenian. Converts whole numbers from 0 up to 999 999 999.

Text is produced in Armenian script (UTF-8).

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::HYE::Num2Word;

 my $text = Lingua::HYE::Num2Word::num2hye_cardinal( 123 );
 print $text || "sorry, can't convert this number into Armenian.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2hye_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to Armenian text representation.
Only numbers from interval [0, 999_999_999] will be converted.

=item B<capabilities> (void)

  =>  hashref  supported features

Returns a hashref indicating which conversion types are supported.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2hye_cardinal

=back

=cut

# }}}
# {{{ POD FOOTER

=pod

=head1 AUTHORS

 specification, maintenance:
   Richard C. Jelinek E<lt>rj@petamem.comE<gt>
 coding:
   PetaMem AI Coding Agents

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2002-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
