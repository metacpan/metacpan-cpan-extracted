package Lingua::RU::NameParse;

use 5.008;
use strict;
use warnings;


our $VERSION = '0.02';


sub new { my $class = shift; 
		  bless {}, $class; }




=item normalize NAME

Given a first name and a patronymic, returns the name and patronymic in the nominative
case.

=cut


sub normalize {
	
	
	
	my ( $self, $testme ) = @_;
	
	use utf8;

	# voodo to set the string's UTF8 flag
	$testme = pack 'U*', unpack( 'U*', $testme ); 
 
	my ( $w1, $w2 ) = split m/\s+/, $testme;
	
	
	##################
	# 	 ACCUSATIVE
	##################
	if (  $w2 =~ /[чк]а$/ ) {
		$w2 =~ s/а$//g;
		$w1 =~ s/а$//g;
		$w1 =~ s/я$/й/g;
	}
	
	elsif ( $w2 =~ /овну\b/ ) {
		$w2 =~ s/у\b/а/;
		$w1 =~ s/ью\b/ья/;
		$w1 =~ s/ию\b/ия/;
	}
	
	################
	# 	 DATIVE
	################
	elsif (  $w2 =~ /не\b/ ) {
		$w2 =~ s/е\b/а/;
		$w1 =~ s/ье\b/ья/;
		$w1 =~ s/е\b/а/;
		$w1 =~ s/ии\b/ия/;
	}
	
	elsif (  $w2 =~ /че\b/ ) {
		$w2 =~ s/е$//;
		$w1 =~ s/ее\b/ей/;  # aleksei
	}
	
	# Константину Левину
	elsif (  $w2 =~ /[нч]у$/ ) {
		$w2 =~ s/у$//;
		$w1 =~ s/у\b//;
		$w1 =~ s/([еи])ю\b/$1й/;
	}
	

	###################
	#   INSTRUMENTAL
	###################
	# Верой Павловною
	elsif (  $w2 =~ /но[юй]$/ ) {

		$w2 =~ s/ою$/а/;
		$w2 =~ s/ой$/а/;
		$w1 =~ s/ой$/а/;
		$w1 =~ s/ею/я/;
		$w1 =~ s/ей/я/;
	}
	

	elsif (  $w2 =~ /ем$/ ) {
		$w2 =~ s/ем\b//;
		$w1 =~ s/ом\b//;
		$w1 =~ s/еем\b/ей/;		
	}
	
	elsif ( $w2 =~ /ым\b/ ) {
		$w2 =~ s/ым/ый/;
	}

	###################
	#   GENITIVE
	###################
	elsif (  $w2 =~ /ны$/ ) {
		$w2 =~ s/ы$/а/g;
		$w1 =~ s/ы$/а/g;
		$w1 =~ s/ьи$/ья/;
	}
	
	elsif (  $w2 =~ /ого$/ ) {
		$w2 =~ s/ого\b/ий/g;
		$w1 =~ s/а$//g;
	}
	
	$w1 =~ s/вл\b/вел/; # pavel
	
	return "$w1 $w2";
}

=item transliterate STRING

Transliterates the string from Cyrillic to Latin.

=cut


sub transliterate {
	my ( $self, $in ) = @_;
	
 
 	for ( $in ) {
 		s/ц/ts/gi;
		s/ш/sh/gi;
		s/щ/shch/gi;
		s/ж/zh/gi;
		s/я/ya/gi;
		s/я\b/ya/gi;
		s/ч/ch/g;
		s/ч\b/ch/g;
		s/ю/yu/gi;
 
		tr/йукнгзхфывапролдэсмитеьбБЙУКЕНГЗХФЫВАПРОЛДЭСМИТ/jukngzhfyvaproldesmite'bBJUKENGZHFYVAPROLDESMIT/;
	}
	
	
	return $in;

}

1;
__END__


=head1 NAME

Lingua::RU::NameParse - Normalize Russian names

=head1 SYNOPSIS

  use Lingua::EN::NameParse;
  
  my $p = Lingua::EN::NameParse->new();
  
  my $norm = $p->normalize("Карлу Марксу");
  

=head1 DESCRIPTION

Takes case endings off of Russian proper names, and normalizes
them to the nominative.  For the moment works only with first name + 
patronymic.

=head1 AUTHOR

Maciej Ceglowski E<lt>maciej@ceglowski.comE<gt>


=cut
