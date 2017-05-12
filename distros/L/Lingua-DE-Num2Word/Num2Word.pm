# For Emacs: -*- mode:cperl; mode:folding; coding:iso-8859-1 -*-
#
# (c) 2002-2004 PetaMem, s.r.o.
#
# PPCG: 0.7

package Lingua::DE::Num2Word;

use strict;

# {{{ BEGIN
#
BEGIN {
  use Exporter ();
  use vars qw($VERSION $REVISION @ISA @EXPORT_OK);
  $VERSION    = '0.03';
  ($REVISION) = '$Revision: 1.10 $' =~ /([\d.]+)/;
  @ISA        = qw(Exporter);
  @EXPORT_OK  = qw(&num2de_cardinal);
}
# }}}

# {{{ num2de_cardinal                 convert number to text
#
sub num2de_cardinal {
  my $positive = shift;

  my @tokens1 = qw(null ein zwei drei vier fünf sechs sieben acht neun zehn elf zwölf);
  my @tokens2 = qw(zwanzig dreissig vierzig fünfzig sechzig siebzig achtzig neunzig hundert);

  return $tokens1[$positive]           if($positive >= 0 && $positive < 13); # 0 .. 12
  return 'sechzehn'                    if($positive == 16);                  # 16 exception
  return 'siebzehn'                    if($positive == 17);                  # 17 exception
  return $tokens1[$positive-10].'zehn' if($positive > 12 && $positive < 20); # 13 .. 19

  my $out;          # string for return value construction
  my $one_idx;      # index for tokens1 array
  my $remain;       # remainder

  if($positive > 19 && $positive < 101) {              # 20 .. 100
    $one_idx = int ($positive / 10);
    $remain = $positive % 10;

    $out = "$tokens1[$remain]und" if $remain;
    $out .= $tokens2[$one_idx-2];

  } elsif($positive > 100 && $positive < 1000) {       # 101 .. 999
    $one_idx = int ($positive / 100);
    $remain  = $positive % 100;

    $out  = "$tokens1[$one_idx]hundert";
    $out .= $remain ? &num2de_cardinal($remain) : '';

  } elsif($positive > 999 && $positive < 1_000_000) {  # 1000 .. 999_999
    $one_idx = int ($positive / 1000);
    $remain  = $positive % 1000;

    $out  = &num2de_cardinal($one_idx).'tausend';
    $out .= $remain ? &num2de_cardinal($remain) : '';

  } elsif($positive > 999_999 &&
	  $positive < 1_000_000_000) {                 # 1_000_000 .. 999_999_999
    $one_idx = int ($positive / 1000000);
    $remain  = $positive % 1000000;
    my $one  = $one_idx == 1 ? 'e' : '';

    $out = &num2de_cardinal($one_idx)."$one million";
    $out .= 'en' if $one_idx > 1;
    $out .= $remain ? ' '.&num2de_cardinal($remain) : '';
  }

  return $out;
}

# }}}

1;
__END__

# {{{ module documentation

=head1 NAME

Lingua::DE::Num2Word - positive number to text convertor for german. Output
text is in iso-8859-1 encoding.

=head1 SYNOPSIS

 use Lingua::DE::Num2Word;
 
 my $text = Lingua::DE::Num2Word::num2de_cardinal( 123 );
 
 print $text || "sorry, can't convert this number into german language.";

=head1 DESCRIPTION

Lingua::DE::Num2Word is module for converting numbers into their representation
in german. Converts whole numbers from 0 up to 999 999 999.

=head2 Functions

=over

=item * num2de_cardinal(number)

Convert number to text representation.

=back

=head1 EXPORT_OK

num2de_cardinal

=head1 KNOWN BUGS

None.

=head1 AUTHOR

Richard Jelinek E<lt>rj@petamem.comE<gt>,
Roman Vasicek E<lt>rv@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2002-2004 PetaMem s.r.o. - L<http://www.petamem.com/>

This package is free software. Tou can redistribute and/or modify it under
the same terms as Perl itself.

=cut

# }}}



