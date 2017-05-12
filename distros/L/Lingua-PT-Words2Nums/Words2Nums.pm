package Lingua::PT::Words2Nums;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	word2num
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '1.04';

=head1 NAME

Lingua::PT::Words2Nums - Converts Portuguese words to numbers

=head1 SYNOPSIS

  use Lingua::PT::Words2Nums qw/word2num/;

  $result = num2word("cinco");
  # $result now holds 5

=head1 DESCRIPTION

Words2Nums converts Portuguese words to numbers (works with numbers
ranging from 0 to 999.999.999.999.999.999).

Not all possible ways to write a number have been implemented (some
people write "nove mil novecentos e um", some people write "nove mil,
novecentos e um"; Words2Nums currently supports only the first way,
without commas; also, the word "bilião" is supported, but not "bilhão").

=cut

my (%values,@values,%bigvalues,@bigvalues);

BEGIN {
  %values = (
    mil			=> 1000,

    novecentos		=> 900,
    oitocentos		=> 800,
    setecentos		=> 700,
    seiscentos		=> 600,
    quinhentos		=> 500,
    quatrocentos	=> 400,
    trezentos		=> 300,
    duzentos		=> 200,
    cem			=> 100,

    cento		=> 100,

    noventa		=> 90,
    oitenta		=> 80,
    setenta		=> 70,
    sessenta		=> 60,
    cinquenta		=> 50,
    quarenta		=> 40,
    trinta		=> 30,
    vinte		=> 20,

    dezanove		=> 19,
    dezoito		=> 18,
    dezassete		=> 17,
    dezasseis		=> 16,
    quinze		=> 15,
    catorze		=> 14,
    treze		=> 13,
    doze		=> 12,
    onze		=> 11,
    dez			=> 10,

    nove		=> 9,
    oito		=> 8,
    sete		=> 7,
    seis		=> 6,
    cinco		=> 5,
    quatro		=> 4,
    'três'		=> 3,
    dois		=> 2,
    um			=> 1,
  );

  @values = sort {$values{$b} <=> $values{$a}} keys %values;

  %bigvalues = (
    bili => 1000000000000,
    milh => 1000000,
  );

  @bigvalues = sort {$bigvalues{$b} <=> $bigvalues{$a}} keys %bigvalues;

}

=head2 word2num

Turns a word into a number

  $result = num2word("cinco");
  # $result now holds 5

=cut

sub word2num {
  $_ = shift || return undef;
  my $result = 0;

  for my $val (@bigvalues) {
    my $expr = "${val}ões|${val}ão";

    if (s/(.+)mil(?=.*(?:$expr))//) {
      my $big = $1;
      for my $value (@values) {
        $big =~ s/$value/
                  $result += ($values{$value} * $bigvalues{$val} * 1000)/e;
      }
    }

    if (s/(.+)(?:$expr)//) {
      my $sma = $1;
      for my $value (@values) {
        $sma =~ s/$value/
                  $result += ($values{$value} * $bigvalues{$val})/e;
      } 
    }

  }

  if (s/(.+?)mil//) {
    my $thousands = $1;
    if ($thousands =~ /^\s*e?\s*$/) {
      $result += 1000;
    }
    else {
      for my $value (@values) {
	$thousands =~ s/$value/$result += ($values{$value} * 1000)/e;
      }
    }
  }

  for my $value (@values) {
    s/$value/$result += $values{$value}/e;
  }

  $result;
}

1;
__END__

=head1 TO DO

=over 6

=item Implement function is_number()

=back

=head1 SEE ALSO

More tools for the Portuguese language processing can be found at the
Natura project: http://natura.di.uminho.pt

=head1 AUTHOR

Jose Castro, C<< <cog@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2004 Jose Castro, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
