# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::DAN::Num2Word;
# ABSTRACT: Number to word conversion in Danish

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

# {{{ num2dan_cardinal                 convert number to text

sub num2dan_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    my @tokens1 = qw(nul en to tre fire fem seks syv otte ni ti elleve tolv);
    my @teens   = qw(tretten fjorten femten seksten sytten atten nitten);
    my @tokens2 = qw(tyve tredive fyrre halvtreds tres halvfjerds firs halvfems);

    return $tokens1[$positive]              if ($positive >= 0 && $positive < 13); # 0 .. 12
    return $teens[$positive - 13]           if ($positive > 12 && $positive < 20); # 13 .. 19

    my $out;          # string for return value construction
    my $one_idx;      # index for tokens1 array
    my $remain;       # remainder

    if ($positive > 19 && $positive < 100) {              # 20 .. 99
        $one_idx = int ($positive / 10);
        $remain  = $positive % 10;

        $out  = "$tokens1[$remain]og" if ($remain);
        $out .= $tokens2[$one_idx - 2];
    }
    elsif ($positive > 99 && $positive < 1000) {         # 100 .. 999
        $one_idx = int ($positive / 100);
        $remain  = $positive % 100;

        # Danish uses "et" (neuter) before hundrede, not "en" (common)
        my $prefix = $one_idx == 1 ? 'et' : $tokens1[$one_idx];
        $out  = "${prefix}hundrede";
        $out .= $remain ? num2dan_cardinal($remain) : '';
    }
    elsif ($positive > 999 && $positive < 1_000_000) {   # 1000 .. 999_999
        $one_idx = int ($positive / 1000);
        $remain  = $positive % 1000;

        $out  = num2dan_cardinal($one_idx).'tusind';
        $out .= $remain ? num2dan_cardinal($remain) : '';
    }
    elsif (   $positive > 999_999
           && $positive < 1_000_000_000) {                 # 1_000_000 .. 999_999_999
        $one_idx = int ($positive / 1000000);
        $remain  = $positive % 1000000;

        $out  = num2dan_cardinal($one_idx) . ' million';
        $out .= 'er' if ($one_idx > 1);
        $out .= $remain ? ' ' . num2dan_cardinal($remain) : '';
    }

    return $out;
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::DAN::Num2Word - Number to word conversion in Danish


=head1 VERSION

version 0.2603260

Lingua::DAN::Num2Word is module for converting numbers into their written
representation in Danish. Converts whole numbers from 0 up to 999 999 999.

Text is encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::DAN::Num2Word;

 my $text = Lingua::DAN::Num2Word::num2dan_cardinal( 123 );

 print $text || "sorry, can't convert this number into danish language.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2dan_cardinal> (positional)

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

=item num2dan_cardinal

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
