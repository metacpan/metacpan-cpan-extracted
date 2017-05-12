# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8 -*-

package Lingua::DEU::Num2Word;
# ABSTRACT: Number 2 word conversion in DEU.

# {{{ use block

use 5.10.1;

use strict;
use warnings;
use utf8;

use Carp;
use Readonly;
use Perl6::Export::Attrs;

# }}}
# {{{ variable declarations

my Readonly::Scalar $COPY = 'Copyright (C) PetaMem, s.r.o. 2002-present';

our $VERSION = 0.1106;

# }}}

# {{{ num2deu_cardinal                 convert number to text

sub num2deu_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999;

    my @tokens1 = qw(null ein zwei drei vier fünf sechs sieben acht neun zehn elf zwölf);
    my @tokens2 = qw(zwanzig dreissig vierzig fünfzig sechzig siebzig achtzig neunzig hundert);

    return $tokens1[$positive]           if ($positive >= 0 && $positive < 13); # 0 .. 12
    return 'sechzehn'                    if ($positive == 16);                  # 16 exception
    return 'siebzehn'                    if ($positive == 17);                  # 17 exception
    return $tokens1[$positive-10] . 'zehn' if ($positive > 12 && $positive < 20); # 13 .. 19

    my $out;          # string for return value construction
    my $one_idx;      # index for tokens1 array
    my $remain;       # remainder

    if ($positive > 19 && $positive < 101) {              # 20 .. 100
        $one_idx = int ($positive / 10);
        $remain  = $positive % 10;

        $out  = "$tokens1[$remain]und" if ($remain);
        $out .= $tokens2[$one_idx - 2];
    }
    elsif ($positive > 100 && $positive < 1000) {       # 101 .. 999
        $one_idx = int ($positive / 100);
        $remain  = $positive % 100;

        $out  = "$tokens1[$one_idx]hundert";
        $out .= $remain ? num2deu_cardinal($remain) : '';
    }
    elsif ($positive > 999 && $positive < 1_000_000) {  # 1000 .. 999_999
        $one_idx = int ($positive / 1000);
        $remain  = $positive % 1000;

        $out  = num2deu_cardinal($one_idx).'tausend';
        $out .= $remain ? num2deu_cardinal($remain) : '';
    }
    elsif (   $positive > 999_999
           && $positive < 1_000_000_000) {                 # 1_000_000 .. 999_999_999
        $one_idx = int ($positive / 1000000);
        $remain  = $positive % 1000000;
        my $one  = $one_idx == 1 ? 'e' : '';

        $out  = num2deu_cardinal($one_idx) . "$one million";
        $out .= 'en' if ($one_idx > 1);
        $out .= $remain ? ' ' . num2deu_cardinal($remain) : '';
    }

    return $out;
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=head1 NAME

=head2 Lingua::DEU::Num2Word  

=head1 VERSION

version 0.1106

Number 2 word conversion in DEU.

Lingua::DEU::Num2Word is module for converting numbers into their written
representationin German. Converts whole numbers from 0 up to 999 999 999.

Text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::DEU::Num2Word;

 my $text = Lingua::DEU::Num2Word::num2deu_cardinal( 123 );

 print $text || "sorry, can't convert this number into german language.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2deu_cardinal> (positional)

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

=item num2deu_cardinal


=back

=cut

# }}}
# {{{ POD FOOTER

=pod

=head1 AUTHOR

 coding, maintenance, refactoring, extensions, specifications:

   Roman Vasicek <info@petamem.com>

=head1 COPYRIGHT

Copyright (C) PetaMem, s.r.o. 2002-present

=cut

# }}}
