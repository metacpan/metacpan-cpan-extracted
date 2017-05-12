package Lingua::PT::Ords2Nums;

use 5.006;
use strict;
use warnings;

use Lingua::PT::Words2Nums qw/word2num/;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	ord2num
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.07';

my %values;

=head1 NAME

Lingua::PT::Ords2Nums - Converts Portuguese ordinals to numbers

=head1 SYNOPSIS

  use Lingua::PT::Ords2Nums qw/ord2num/;

  $num = word2num('décimo primeiro')   # 11

=head1 DESCRIPTION

Converts Portuguese ordinals to numbers. Works up to 999.999.999.999
('novecentos e noventa e nove bilionésimos novecentos e noventa e nove
milionésimos novecentos e noventa e nove milésimos nongentésimo nonagésimo
nono').

=cut

BEGIN {
  %values = (
    'bilionésimo'	=> 1000000000,
    'milionésimo'	=> 1000000,
    'milésimo'		=> 1000,

    'nongentésimo'	=> 900,
    'octigentésimo'	=> 800,
    'septigentésimo'	=> 700,
    'seiscentésimo'	=> 600,
    'quingentésimo'	=> 500,
    'quadrigentésimo'	=> 400,
    'tricentésimo'	=> 300,
    'ducentésimo'	=> 200,
    'centésimo' 	=> 100,

    'nonagésimo'	=> 90,
    'octogésimo' 	=> 80,
    'septuagésimo' 	=> 70,
    'sexagésimo' 	=> 60,
    'quinquagésimo' 	=> 50,
    'quadragésimo' 	=> 40,
    'trigésimo' 	=> 30,
    'vigésimo' 		=> 20,
    'décimo' 		=> 10,

    nono		=> 9,
    oitavo		=> 8,
    'sétimo'		=> 7,
    sexto		=> 6,
    quinto		=> 5,
    quarto		=> 4,
    terceiro		=> 3,
    segundo		=> 2,
    primeiro		=> 1,

  );
}

=head2 ord2num

Turns an ordinal number into a regular number (decimal).

  $num = word2num('segundo')
  # $num now holds 2

=cut

sub ord2num {
  $_ = shift || return undef;
  my $result = 0;

  s/(.*)bilionésimos/$result += (word2num($1) * 1000000000)/e;
  s/(.*)milionésimos/$result += (word2num($1) * 1000000)/e;
  s/(.*)milésimos/$result += (word2num($1) * 1000)/e;

  for my $value (keys %values) {
    s/$value/$result += $values{$value}/e;
  }

  $result;
}

1;
__END__

=head1 DEPENDENCIES

Lingua::PT::Words2Nums

=head1 TO DO

=over 6

=item * Implement function isord()

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
