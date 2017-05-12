# For Emacs: -*- mode:cperl; mode:folding; coding:iso-8859-2; -*-
#
# (c) 2002-2004 PetaMem, s.r.o.
#
# PPCG: 0.7
#

package Lingua::CS::Num2Word;

# {{{ use block

use strict;

# }}}

# {{{ BEGIN

BEGIN {
  use Exporter ();
  use vars qw($VERSION $REVISION @ISA @EXPORT_OK);
  $VERSION    = 0.03;
  ($REVISION) = '$Revision: 1.14 $' =~ /([\d.]+)/;
  @ISA        = qw(Exporter);
  @EXPORT_OK  = qw(&num2cs_cardinal);
}

# }}}

# {{{ variables

my %token1 = qw( 0 nula         1 jedna         2 dva
                 3 tøi          4 ètyøi         5 pìt
                 6 ¹est         7 sedm          8 osm
                 9 devìt        10 deset        11 jedenáct
                 12 dvanáct     13 tøináct      14 ètrnáct
                 15 patnáct     16 ¹estnáct     17 sedmnáct
                 18 osmnáct     19 devatenáct
               );
my %token2 = qw( 20 dvacet      30 tøicet       40 ètyøicet
                 50 padesát     60 ¹edesát      70 sedmdesát
                 80 osmdesát    90 devadesát
               );
my %token3 = (  100, 'sto', 200, 'dvì stì',   300, 'tøi sta',
                400, 'ètyøi sta', 500, 'pìt set',   600, '¹est set',
                700, 'sedm set',  800, 'osm set',   900, 'devìt set'
	     );

# }}}

# {{{ num2cs_cardinal           number to string conversion

sub num2cs_cardinal {
  my $result = '';
  my $number = defined $_[0] ? shift : return $result;

  # numbers less than 0 are not supported yet
  return $result if $number < 0;

  my $reminder = 0;

  if ($number < 20) {
    $result = $token1{$number};
  } elsif ($number < 100) {
    $reminder = $number % 10;
    if ($reminder == 0) {
      $result = $token2{$number};
    } else {
      $result = $token2{$number - $reminder}.' '.num2cs_cardinal($reminder);
    }
  } elsif ($number < 1_000) {
    $reminder = $number % 100;
    if ($reminder != 0) {
      $result = $token3{$number - $reminder}.' '.num2cs_cardinal($reminder);
    } else {
      $result = $token3{$number};
    }
  } elsif ($number < 1_000_000) {
    $reminder = $number % 1_000;
    my $tmp1 = ($reminder != 0) ? ' '.num2cs_cardinal($reminder) : '';
    my $tmp2 = substr($number, 0, length($number)-3);
    my $tmp3 = $tmp2 % 100;
    my $tmp4 = $tmp2 % 10;

    if ($tmp3 < 9 || $tmp3 > 20) {

      if ($tmp4 == 1 && $tmp2 == 1) {
	$tmp2 = 'tisíc';
      } elsif ($tmp4 == 1) {
	$tmp2 = num2cs_cardinal($tmp2 - $tmp4).' jeden tisíc';
      } elsif($tmp4 > 1 && $tmp4 < 5) {
	$tmp2 = num2cs_cardinal($tmp2).' tisíce';
      } else {
	$tmp2 = num2cs_cardinal($tmp2).' tisíc';
      }
    } else {
      $tmp2 = num2cs_cardinal($tmp2).' tisíc';
    }

    $result = $tmp2.$tmp1;

  } elsif ($number < 1_000_000_000) {
    $reminder = $number % 1_000_000;
    my $tmp1 = ($reminder != 0) ? ' '.num2cs_cardinal($reminder) : '';
    my $tmp2 = substr($number, 0, length($number)-6);
    my $tmp3 = $tmp2 % 100;
    my $tmp4 = $tmp2 % 10;

    if ($tmp3 < 9 || $tmp3 > 20) {

      if ($tmp4 == 1 && $tmp2 == 1) {
	$tmp2 = 'milion';
      } elsif ($tmp4 == 1) {
	$tmp2 = num2cs_cardinal($tmp2 - $tmp4).' jeden milion';
      } elsif($tmp4 > 1 && $tmp4 < 5) {
	$tmp2 = num2cs_cardinal($tmp2).' miliony';
      } else {
	$tmp2 = num2cs_cardinal($tmp2).' milionù';
      }
    } else {
      $tmp2 = num2cs_cardinal($tmp2).' milionù';
    }

    $result = $tmp2.$tmp1;

  } else {
    # >= 1 000 000 000 unsupported yet (miliard)
  }

  return $result;
}

# }}}

1;
__END__

# {{{ documentation

=head1 NAME

Lingua::CS::Num2Word -  number to text convertor for czech. Output
text is in iso-8859-2 encoding.

=head1 SYNOPSIS

 use Lingua::CS::Num2Word;
 
 my $text = Lingua::CS::Num2Word::num2cs_cardinal( 123 );
 
 print $text || "sorry, can't convert this number into czech language.";

=head1 DESCRIPTION

Lingua::CS::Num2Word is module for convertion numbers into their representation
in czech. Converts whole numbers from 0 up to 999 999 999.

=head2 Functions

=over

=item * num2cs_cardinal(number)

Convert number to text representation.

=back

=head1 EXPORT_OK

num2cs_cardinal

=head1 KNOWN BUGS

None.

=head1 AUTHOR

Roman Vasicek E<lt>rv@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2002-2004 PetaMem s.r.o. - L<http://www.petamem.com/>

This package is free software. You can redistribute and/or modify it under
the same terms as Perl itself.

=cut

# }}}
