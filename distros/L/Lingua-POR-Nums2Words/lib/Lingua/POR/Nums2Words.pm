# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::POR::Nums2Words;
# ABSTRACT: Number 2 word conversion in POR.

# {{{ use block

use 5.10.1;
use strict;
use warnings;
use utf8;

use Perl6::Export::Attrs;

# }}}
# {{{ variables declaration

our $VERSION = 0.0682;

# }}}

# {{{ num2word
sub num2word :Export {
  my @a = @_;
  @a || return ();
  my @numbers = wantarray ? @a : shift @a;
  my @results = map { ## no critic
    $_ < 0 && return $_;
    #$_ > 999999999999999999 && return $_;
    $_ > 999999999999999 && return $_;
    if ( $_ > 999999999999 ) {
      my ($bil,$mil) = /(.*)(\d{12})$/;
      my $a = num2word($bil);
      my $b = num2word($mil);
      my $e = "";
      if ($b && $mil =~ /^0{9}/) {
        $e = " e";
      }
      my $s = $b ? ' ' : '';
      return $a . ($bil == 1 ? ' biliăo' : ' biliőes') . $e . $s . $b;
    }
    elsif ( $_ > 999999 ) {
      my ($mil,$uni) = /(.*)(\d{6})$/;
      my $a = num2word($mil);
      my $b = num2word($uni);
      my $e = "";
      my $s = $b ? ' ' : '';
      if ($uni =~ /^000\d{0,2}[1-9]\d{0,2}|0\d?[1-9]\d?000|[1-9]0{5}/) {
        $e = " e";
      }
      return $a . ($mil == 1 ? ' milhăo' : ' milhőes') . $e . $s . $b;
    }
    elsif ( $_ > 9999 ) {
      $_ =~ /\d\d\d$/;
      my $a = num2word($`);
      my $b = num2word( 1000 + $& );
      return "$a $b";
    }
    else {
      s!^00+!!;
      s!^0+(?=[1-9])!!;
      s!9(?=\d\d\d)!nove mil e !;
      s!8(?=\d\d\d)!oito mil e !;
      s!7(?=\d\d\d)!sete mil e !;
      s!6(?=\d\d\d)!seis mil e !;
      s!5(?=\d\d\d)!cinco mil e !;
      s!4(?=\d\d\d)!quatro mil e !;
      s!3(?=\d\d\d)!tręs mil e !;
      s!2(?=\d\d\d)!dois mil e !;
      s!1(?=\d\d\d)!mil e !;
      s!9(?=\d\d)!novecentos e !;
      s!8(?=\d\d)!oitocentos e !;
      s!7(?=\d\d)!setecentos e !;
      s!6(?=\d\d)!seiscentos e !;
      s!5(?=\d\d)!quinhentos e !;
      s!4(?=\d\d)!quatrocentos e !;
      s!3(?=\d\d)!trezentos e !;
      s!2(?=\d\d)!duzentos e !;
      s!100!cem!;
      s!mil e 0+(?=[1-9])!mil e !;
      s!1(?=\d\d)!cento e !;
      s!9(?=\d)!noventa e !;
      s!8(?=\d)!oitenta e !;
      s!7(?=\d)!setenta e !;
      s!6(?=\d)!sessenta e !;
      s!5(?=\d)!cinquenta e !;
      s!4(?=\d)!quarenta e !;
      s!3(?=\d)!trinta e !;
      s!2(?=\d)!vinte e !;
      s/ e 0+(?=[1-9])/ e /;
      s/ e 0+//;
      s/19/dezanove/;
      s/18/dezoito/;
      s/17/dezassete/;
      s/16/dezasseis/;
      s/15/quinze/;
      s/14/catorze/;
      s/13/treze/;
      s/12/doze/;
      s/11/onze/;
      s/10/dez/;
      s/9/nove/;
      s/8/oito/;
      s/7/sete/;
      s/6/seis/;
      s/5/cinco/;
      s/4/quatro/;
      s/3/tręs/;
      s/2/dois/;
      s/1/um/;
      s/0/zero/;

      s!mil e (novecentos|oitocentos|setecentos|seiscentos) e!mil $1 e!;
      s!mil e (quinhentos|quatrocentos|trezentos|duzentos) e!mil $1 e!;
      s!mil e cento!mil cento!;

      $_;
    }
  } @numbers;

  return wantarray ? @results : $results[0];
}

# }}}

1;
__END__

# {{{ module documentation

=head1 NAME

Lingua::POR::Nums2Words - Converts numbers to Portuguese words

=head1 VERSION

version 0.0682

=head1 SYNOPSIS

  use Lingua::POR::Nums2Words qw/num2word/;

  $result = num2word(5);
  # $result now holds 'cinco'

  @results = num2word(1,2,10,100,1000,9999);
  # @results now holds ('um', 'dois', 'dez', 'cem', 'mil',
  #                     'nove mil novecentos e noventa e nove')

=head1 DESCRIPTION

Number 2 word conversion in POR.

Nums2Words converts numbers to Portuguese words (works with numbers
ranging from 0 to 999.999.999.999.999).

Does not support negative numbers.

=head2 num2word

This is the only function in this module. It turns numbers into words.

  $number = num2word(77);
  # $number now holds "setenta e sete"





=head1 SEE ALSO

More tools for the Portuguese language processing can be found at the
Natura project: http://natura.di.uminho.pt

=head1 AUTHOR

Jose Castro, <cog@cpan.org>

Maintenance
Petamem s.r.o., <info@petamem.com>

=head1 COPYRIGHT & LICENSE

Copyright 2004 Jose Castro, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# }}}
