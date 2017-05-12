package MILA::Transliterate;
use utf8;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(hebrew2treebank treebank2hebrew hebrew2erel erel2hebrew hebrew2fsma fsma2hebrew);
our $VERSION = 0.01;
=head1 NAME

MILA::Transliterate - A Perl Module for transliterating text from Hebrew to various transliterations used in the Knowledge Center for Processing Hebrew (MILA) and vise versa

=head1 SYNOPSIS

	use MILA::Transliterate qw((hebrew2treebank hebrew2erel hebrew2fsma);
	my $erel_transliterated = hebrew2erel($utf8_encoded_hebrew_text);
	my $treebank_transliterated = hebrew2treebank($utf8_encoded_hebrew_text);
	my $fsma_transliterated = hebrew2fsma($utf8_encoded_hebrew_text);

	# note that the reverse transliteration does NOT maintain final Hebrew letters!

=head1 DESCRIPTION

Before UNICODE was widely used, applications that were manipulating Hebrew text usually used  some transliteration into ASCII characters instead of using Hebrew letters. This was particularly true for software developed in the academia. MILA is a nick name for the Knowledge Center for Processing Hebrew (see: http://mila.cs.technion.ac.il/). This knowledge center develops software and standards that result from research in natural language processing for Hebrew. As a result, some legacy software also needs to be maintained and such legacy software usually used transliteration.

This module contains mapping from UTF-8 encoded Hebrew to the various transliteration schemes that MILA needs to support and also contains the reversed mapping.

=head1 FUNCTIONS

=item $treebank_transliterated = hebrew2treebank( $utf8_encoded_hebrew_text )

This function maps UTF-8 encoded Hebrew text into the treebank transliteration. Every character not in the mapping is being copied as is without any conversion.

=item $erel_transliterated = hebrew2erel( $utf8_encoded_hebrew_text )

This function maps UTF-8 encoded Hebrew text into the erel transliteration. Every character not in the mapping is being copied as is without any conversion.

=item $fsma_transliterated = hebrew2fsma( $utf8_encoded_hebrew_text )

This function maps UTF-8 encoded Hebrew text into the fsma transliteration. Every character not in the mapping is being copied as is without any conversion.

=item $utf8_encoded_hebrew_text = treebank2hebrew( $treebank_transliterated )

This function provides the reverse transliteration that is provided by hebrew2treebank(). Note that final letters are not preserved and are lost.

=item $utf8_encoded_hebrew_text = erel2hebrew( $erel_transliterated )

This function provides the reverse transliteration that is provided by hebrew2erel(). Note that final letters are not preserved and are lost.

=item $utf8_encoded_hebrew_text = fsma2hebrew( $fsma_transliterated )

This function provides the reverse transliteration that is provided by hebrew2fsma(). Note that final letters are not preserved and are lost.

=item AUTHOR

Shlomo Yona yona@cs.technion.ac.il http://cs.haifa.ac.il/~shlomo/

=head1 COPYRIGHT

Copyright (c) 20042 Shlomo Yona. All rights reserved.

This library is free software. 
You can redistribute it and/or modify it under the same terms as Perl itself.  

=head1 CVS INFO

$Revision: 1.1 $
$Date: 2004/12/17 09:17:37 $

=cut

# UTF-8 Encoded Hebrew letters mapped to Treebank alphabet
my %h2t =(
א => 'A',
ב => 'B',
ג => 'G',
ד => 'D',
ה => 'H',
ו => 'W',
ז => 'Z',
ח => 'X',
ט => 'J',
י => 'I',
ך => 'K',
כ => 'K',
ל => 'L',
ם => 'M',
מ => 'M',
ן => 'N',
נ => 'N',
ס => 'S',
ע => 'E',
ף => 'P',
פ => 'P',
ץ => 'C',
צ => 'C',
ק => 'Q',
ר => 'R',
ש => 'F',
ת => 'T',
'"' => 'U',
'%' => 'O',
);

# Treebank alphabet mapped to UTF-8 Encoded Hebrew letters 
my %t2h=(
'A' => 'א',
'B' => 'ב',
'G' => 'ג',
'D' => 'ד',
'H' => 'ה',
'W' => 'ו',
'Z' => 'ז',
'X' => 'ח',
'J' => 'ט',
'I' => 'י',
'K' => 'כ',
'L' => 'ל',
'M' => 'ם',
'M' => 'מ',
'N' => 'נ',
'S' => 'ס',
'E' => 'ע',
'P' => 'פ',
'C' => 'צ',
'Q' => 'ק',
'R' => 'ר',
'F' => 'ש',
'T' => 'ת',
'U' => '"',
'O' => '%',
);

# UTF-8 encoded Hebrew letters mapped to Erel's alphabet
my %h2e =(
א => 'A',
ב => 'B',
ג => 'G',
ד => 'D',
ה => 'H',
ו => 'W',
ז => 'Z',
ח => 'X',
ט => '@',
י => 'I',
ך => 'K',
כ => 'K',
ל => 'L',
ם => 'M',
מ => 'M',
ן => 'N',
נ => 'N',
ס => 'S',
ע => '&',
ף => 'P',
פ => 'P',
ץ => 'C',
צ => 'C',
ק => 'Q',
ר => 'R',
ש => '$',
ת => 'T',
);

# Erel's alphabet mapped to UTF-8 encoded Hebrew letters
my %e2h=(
'A' => 'א',
'B' => 'ב',
'G' => 'ג',
'D' => 'ד',
'H' => 'ה',
'W' => 'ו',
'Z' => 'ז',
'X' => 'ח',
'@' => 'ט',
'I' => 'י',
'K' => 'כ',
'L' => 'ל',
'M' => 'ם',
'M' => 'מ',
'N' => 'נ',
'S' => 'ס',
'&' => 'ע',
'P' => 'פ',
'C' => 'צ',
'Q' => 'ק',
'R' => 'ר',
'$' => 'ש',
'T' => 'ת',
);

# UTF-8 encoded Hebrew letters mapped to FSMA's alphabet
my %h2l =(
א => 'a',
ב => 'b',
ג => 'g',
ד => 'd',
ה => 'h',
ו => 'w',
ז => 'z',
ח => 'x',
ט => 'v',
י => 'i',
ך => 'k',
כ => 'k',
ל => 'l',
ם => 'm',
מ => 'm',
ן => 'n',
נ => 'n',
ס => 's',
ע => 'y',
ף => 'p',
פ => 'p',
ץ => 'c',
צ => 'c',
ק => 'q',
ר => 'r',
ש => 'e',
ת => 't',
);

# FSMA's alphabet mapped to UTF-8 encoded Hebrew letters
my %l2h=(
'a' => 'א',
'b' => 'ב',
'g' => 'ג',
'd' => 'ד',
'h' => 'ה',
'w' => 'ו',
'z' => 'ז',
'x' => 'ח',
'v' => 'ט',
'i' => 'י',
'k' => 'כ',
'l' => 'ל',
'm' => 'ם',
'm' => 'מ',
'n' => 'נ',
's' => 'ס',
'y' => 'ע',
'p' => 'פ',
'c' => 'צ',
'q' => 'ק',
'r' => 'ר',
'e' => 'ש',
't' => 'ת',
);

sub generic_translation {
	my ($from_string,$mapping_hash) = @_;
	my $to_string='';
	foreach my $c (split //,$from_string) {
		if (exists $mapping_hash->{$c}) {
			$to_string.= $mapping_hash->{$c};
		} else{
			$to_string.=$c;
		}
	}
	return $to_string;
}

sub hebrew2treebank {
	my ($hebrew_string) = @_;
	return generic_translation($hebrew_string,\%h2t);
}

sub treebank2hebrew { 
	my ($treebank_string) = @_;
	return generic_translation($treebank_string,\%t2h);
}

sub hebrew2erel {
	my ($hebrew_string) = @_;
	return generic_translation($hebrew_string,\%h2e);
}

sub erel2hebrew { 
	my ($treebank_string) = @_;
	return generic_translation($treebank_string,\%e2h);
}

sub hebrew2fsma {
	my ($hebrew_string) = @_;
	return generic_translation($hebrew_string,\%h2l);
}

sub fsma2hebrew { 
	my ($treebank_string) = @_;
	return generic_translation($treebank_string,\%l2h);
}


1;
