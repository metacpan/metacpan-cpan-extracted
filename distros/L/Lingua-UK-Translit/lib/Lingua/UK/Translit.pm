package Lingua::UK::Translit;

use 5.006;
use strict;
use warnings;
use utf8;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	&uk2ascii
	
);

our $VERSION = '0.10';

my %ua2en = (
	'а' => 'a', 'А' => 'A',
	'б' => 'b', 'Б' => 'B',
	'в' => 'v', 'В' => 'V',
	'г' => 'h', 'Г' => 'H',
	'ґ' => 'g', 'Ґ' => 'G', 
	'д' => 'd', 'Д' => 'D', 
	'е' => 'e', 'Е' => 'E', 
	'є' => 'ie', 'Є' => 'Ie', 
	'ж' => 'zh', 'Ж' => 'Zh', 
	'з' => 'z', 'З' => 'Z', 
	'и' => 'y', 'И' => 'Y', 
	'і' => 'i', 'І' => 'I', 
	'ї' => 'i', 'Ї' => 'I', 
	'й' => 'i', 'Й' => 'I', 
	'к' => 'k', 'К' => 'K',
	'л' => 'l', 'Л' => 'L',
	'м' => 'm', 'М' => 'M',
	'н' => 'n', 'Н' => 'N',
	'о' => 'o', 'О' => 'O',
	'п' => 'p', 'П' => 'P',
	'р' => 'r', 'Р' => 'R',
	'с' => 's', 'С' => 'S',
	'т' => 't', 'Т' => 'T',
	'у' => 'u', 'У' => 'U',
	'ф' => 'f', 'Ф' => 'F',
	'х' => 'kh', 'Х' => 'Kh',
	'ц' => 'ts', 'Ц' => 'Ts',
	'ч' => 'ch', 'Ч' => 'Ch',
	'ш' => 'sh', 'Ш' => 'Sh',
	'щ' => 'sch', 'Щ' => 'Sch',
	'ь' => '\'', 'Ь' => '\'',
	'ю' => 'iu', 'Ю' => 'Iu',
	'я' => 'ia', 'Я' => 'Ia'
);

my %ua2enwb = (
	'є' => 'ye', 'Є' => 'Ye',
	'ї' => 'y', 'Ї' => 'Y',
	'й' => 'y', 'Й' => 'Y',
	'ю' => 'yu', 'Ю' => 'Yu',
	'я' => 'ya', 'Я' => 'Ya'
);


sub uk2ascii
{
	my $strin = shift;

	my @words = split ('\b',$strin);

	my $strans = '';

	foreach my $word (@words){

		my @c = split('',$word);
	
		my $wtrans = '';
	
		for ( my $i = 0; $i <= $#c; $i++){
			if ( ($i == 0) and (exists $ua2enwb{$c[0]}) ){
				$wtrans .= $ua2enwb{$c[0]};
			} elsif (exists $ua2en{$c[$i]}){
				if ( ($c[$i] eq 'г') and (($c[$i-1] eq 'з') or ($c[$i-1] eq 'З')) ){
					$wtrans .= 'gh';
				} elsif ( ($c[$i] eq 'Г') and (($c[$i-1] eq 'з') or ($c[$i-1] eq 'З')) ){
					$wtrans .= 'Gh';
				} else {
					$wtrans .= $ua2en{$c[$i]};
				}
			} else {
				$wtrans .= $c[$i];
			}
		}
		$strans .= $wtrans;
	}
	return $strans;
}

1;
__END__

=head1 NAME

Lingua::UK::Translit - Perl extension for correct transliteration of Ukrainian text in UTF-8 encoding to Latin symbols.

=head1 SYNOPSIS

  use utf8;
  use Lingua::UK::Translit;
  
  my $ukrainian_text="Україна";
  print uk2ascii( $ukrainian_text ), "\n";


=head1 DESCRIPTION

Lingua::UK::Translit is collection of some functions for proper transliteration of Ukrainian text in UTF-8 encoding to Latin symbols.

Consists of functions for proper text transliteration.
Works only with UTF-8 encoding. Returns all symbols in UTF-8 encoding.

=head2 Functions

=over 4

=item * uk2ascii($ukrainian_text)

,where $ukrainian_text - text in UTF-8 encoding.

Returns transliterated text in Latin symbols, but encoded as UTF-8. Transliterates only letters of Ukrainian alphabet, other symbols leaves untouched. Preserves formatting and punctuation.

=back

=head2 EXPORT

sub uk2ascii()

=head1 SEE ALSO

	perl(1) - Practical Extraction and Report Language
	
	Lingua::UK::Jcuken - Conversion between QWERTY and JCUKEN keys in Ukrainian
	
	Lingua::RU::Jcuken - Conversion between QWERTY and JCUKEN keys in Russian
	
	Lingua::RU::PhTranslit - Writing cyrillic(russian) symbols by ASCII symbols (0x20-0x7f)
	
	Lingua::RU::Translit - Converts from Russian "translit" encoding to russian in koi8-r

=head1 AUTHOR

O. Y. Panchuk, E<lt>olex@ucu.edu.uaE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by O. Y. Panchuk

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
