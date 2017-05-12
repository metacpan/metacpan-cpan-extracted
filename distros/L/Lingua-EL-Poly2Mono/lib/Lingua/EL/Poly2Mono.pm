package Lingua::EL::Poly2Mono;
require Exporter;

use strict;   # :-(

use vars qw/
	$VERSION
	@ISA
	@EXPORT_OK
	$OLD_PERL
	
	$C
	$conson
	$psiliaccent_lc
	$gramma
	$diacr
	$ui
	$diphpre
	$accent
	%remove
	%p2m
	%direm
/;

  $VERSION   = 0.02;
  @ISA       = 'Exporter';
# @ISNTA     = 'Deporter';
  @EXPORT_OK = 'poly2mono';

{
	local $@ ;
	eval { require Encode; Encode->import(qw/is_utf8 encode_utf8 decode_utf8/) };
	$@ and ++$OLD_PERL;
}

$C = '(?:[\x00-\x7f]|[\xc0-\xff][\x80-\xbf]+)';
$conson = "Β|Γ|Δ|Ζ|Θ|Κ|Λ|Μ|Ν|Ξ|Π|Ρ|Σ|Τ|Φ|Χ|Ψ|β|γ|δ|ζ|θ|κ|λ|μ|ν|ξ|π|ρ|ς|σ|τ|φ|χ|ψ|ῤ|ῥ|Ῥ";
$psiliaccent_lc="ἂ|ἄ|ἆ|ἒ|ἔ|ἢ|ἤ|ἦ|ἲ|ἴ|ἶ|ὂ|ὄ|ὒ|ὔ|ὖ|ὢ|ὤ|ὦ|ᾂ|ᾄ|ᾆ|ᾒ|ᾔ|ᾖ|ᾢ|ᾤ|ᾦ";
$gramma = "(Ά|Έ|Ή|Ί|Ό|Ύ|Ώ|ΐ|Α|Β|Γ|Δ|Ε|Ζ|Η|Θ|Ι|Κ|Λ|Μ|Ν|Ξ|Ο|Π|Ρ|Σ|Τ|Υ|Φ|Χ|Ψ|Ω|Ϊ|Ϋ|ά|έ|ή|ί|ΰ|α|β|γ|δ|ε|ζ|η|θ|ι|κ|λ|μ|ν|ξ|ο|π|ρ|ς|σ|τ|υ|φ|χ|ψ|ω|ϊ|ϋ|ό|ύ|ώ|ἀ|ἁ|ἂ|ἃ|ἄ|ἅ|ἆ|ἇ|Ἀ|Ἁ|Ἂ|Ἃ|Ἄ|Ἅ|Ἆ|Ἇ|ἐ|ἑ|ἒ|ἓ|ἔ|ἕ|Ἐ|Ἑ|Ἒ|Ἓ|Ἔ|Ἕ|ἠ|ἡ|ἢ|ἣ|ἤ|ἥ|ἦ|ἧ|Ἠ|Ἡ|Ἢ|Ἣ|Ἤ|Ἥ|Ἦ|Ἧ|ἰ|ἱ|ἲ|ἳ|ἴ|ἵ|ἶ|ἷ|Ἰ|Ἱ|Ἲ|Ἳ|Ἴ|Ἵ|Ἶ|Ἷ|ὀ|ὁ|ὂ|ὃ|ὄ|ὅ|Ὀ|Ὁ|Ὂ|Ὃ|Ὄ|Ὅ|ὐ|ὑ|ὒ|ὓ|ὔ|ὕ|ὖ|ὗ|Ὑ|Ὓ|Ὕ|Ὗ|ὠ|ὡ|ὢ|ὣ|ὤ|ὥ|ὦ|ὧ|Ὠ|Ὡ|Ὢ|Ὣ|Ὤ|Ὥ|Ὦ|Ὧ|ὰ|ά|ὲ|έ|ὴ|ή|ὶ|ί|ὸ|ό|ὺ|ύ|ὼ|ώ|ᾀ|ᾁ|ᾂ|ᾃ|ᾄ|ᾅ|ᾆ|ᾇ|ᾈ|ᾉ|ᾊ|ᾋ|ᾌ|ᾍ|ᾎ|ᾏ|ᾐ|ᾑ|ᾒ|ᾓ|ᾔ|ᾕ|ᾖ|ᾗ|ᾘ|ᾙ|ᾚ|ᾛ|ᾜ|ᾝ|ᾞ|ᾟ|ᾠ|ᾡ|ᾢ|ᾣ|ᾤ|ᾥ|ᾦ|ᾧ|ᾨ|ᾩ|ᾪ|ᾫ|ᾬ|ᾭ|ᾮ|ᾯ|ᾲ|ᾳ|ᾴ|ᾶ|ᾷ|Ὰ|Ά|ᾼ|ῂ|ῃ|ῄ|ῆ|ῇ|Ὲ|Έ|Ὴ|Ή|ῌ|ῒ|ΐ|ῖ|ῗ|ῢ|ΰ|ῤ|ῥ|ῦ|ῧ|Ὺ|Ύ|Ῥ|ῲ|ῳ|ῴ|ῶ|ῷ|Ὸ|Ό|Ὼ|Ώ|ῼ)";
$diacr="ϊ|ϋ|ἀ|ἁ|ἂ|ἃ|ἄ|ἅ|ἆ|ἇ|Ἀ|Ἁ|Ἂ|Ἃ|Ἄ|Ἅ|Ἆ|Ἇ|ἐ|ἑ|ἒ|ἓ|ἔ|ἕ|Ἐ|Ἑ|Ἒ|Ἓ|Ἔ|Ἕ|ἠ|ἡ|ἢ|ἣ|ἤ|ἥ|ἦ|ἧ|Ἠ|Ἡ|Ἢ|Ἣ|Ἤ|Ἥ|Ἦ|Ἧ|ἰ|ἱ|ἲ|ἳ|ἴ|ἵ|ἶ|ἷ|Ἰ|Ἱ|Ἲ|Ἳ|Ἴ|Ἵ|Ἶ|Ἷ|ὀ|ὁ|ὂ|ὃ|ὄ|ὅ|Ὀ|Ὁ|Ὂ|Ὃ|Ὄ|Ὅ|ὐ|ὑ|ὒ|ὓ|ὔ|ὕ|ὖ|ὗ|Ὑ|Ὓ|Ὕ|Ὗ|ὠ|ὡ|ὢ|ὣ|ὤ|ὥ|ὦ|ὧ|Ὠ|Ὡ|Ὢ|Ὣ|Ὤ|Ὥ|Ὦ|Ὧ|ὰ|ά|ὲ|έ|ὴ|ή|ὶ|ί|ὸ|ό|ὺ|ύ|ὼ|ώ|ᾀ|ᾁ|ᾂ|ᾃ|ᾄ|ᾅ|ᾆ|ᾇ|ᾈ|ᾉ|ᾊ|ᾋ|ᾌ|ᾍ|ᾎ|ᾏ|ᾐ|ᾑ|ᾒ|ᾓ|ᾔ|ᾕ|ᾖ|ᾗ|ᾘ|ᾙ|ᾚ|ᾛ|ᾜ|ᾝ|ᾞ|ᾟ|ᾠ|ᾡ|ᾢ|ᾣ|ᾤ|ᾥ|ᾦ|ᾧ|ᾨ|ᾩ|ᾪ|ᾫ|ᾬ|ᾭ|ᾮ|ᾯ|ᾲ|ᾳ|ᾴ|ᾶ|ᾷ|Ὰ|Ά|ᾼ|ῂ|ῃ|ῄ|ῆ|ῇ|Ὲ|Έ|Ὴ|Ή|ῌ|ῒ|ΐ|ῖ|ῗ|ῢ|ΰ|ῤ|ῥ|ῦ|ῧ|Ὺ|Ύ|Ῥ|ῲ|ῳ|ῴ|ῶ|ῷ|Ὸ|Ό|Ὼ|Ώ|ῼ";
$ui="ἰ|ἱ|ἲ|ἳ|ἴ|ἵ|ἶ|ἷ|ὐ|ὑ|ὒ|ὓ|ὔ|ὕ|ὖ|ὗ|ὶ|ί|ὺ|ύ|ῖ|ῦ";
$diphpre="Α|Ε|Η|Ο|Υ|α|ε|η|ο|υ";
$accent="ἂ|ἃ|ἄ|ἅ|ἆ|ἇ|Ἂ|Ἃ|Ἄ|Ἅ|Ἆ|Ἇ|ἒ|ἓ|ἔ|ἕ|Ἒ|Ἓ|Ἔ|Ἕ|ἢ|ἣ|ἤ|ἥ|ἦ|ἧ|Ἢ|Ἣ|Ἤ|Ἥ|Ἦ|Ἧ|ἲ|ἳ|ἴ|ἵ|ἶ|ἷ|Ἲ|Ἳ|Ἴ|Ἵ|Ἶ|Ἷ|ὂ|ὃ|ὄ|ὅ|Ὂ|Ὃ|Ὄ|Ὅ|ὒ|ὓ|ὔ|ὕ|ὖ|ὗ|Ὓ|Ὕ|Ὗ|ὢ|ὣ|ὤ|ὥ|ὦ|ὧ|Ὢ|Ὣ|Ὤ|Ὥ|Ὦ|Ὧ|ὰ|ά|ὲ|έ|ὴ|ή|ὶ|ί|ὸ|ό|ὺ|ύ|ὼ|ώ|ᾂ|ᾃ|ᾄ|ᾅ|ᾆ|ᾇᾊ|ᾋ|ᾌ|ᾍ|ᾎ|ᾏ|ᾒ|ᾓ|ᾔ|ᾕ|ᾖ|ᾗ|ᾚ|ᾛ|ᾜ|ᾝ|ᾞ|ᾟ|ᾢ|ᾣ|ᾤ|ᾥ|ᾦ|ᾧ|ᾪ|ᾫ|ᾬ|ᾭ|ᾮ|ᾯ|ᾲ|ᾴ|ᾶ|ᾷ|Ὰ|Ά|ῂ|ῄ|ῆ|ῇ|Ὲ|Έ|Ὴ|Ή|ῒ|ΐ|ῖ|ῗ|ῢ|ΰ|ῦ|ῧ|Ὺ|Ύ|ῲ|ῴ|ῶ|ῷ|Ὸ|Ό|Ὼ|Ώ";

# This is for removing koronides with accents, secondary accents at the
# end of a word, and diereses preceded by accents.
%remove = 
qw(ϊ	ι
ϋ	υ
ἀ	α
ἁ	α
ἂ	α
ἃ	α
ἄ	α
ἅ	α
ἆ	α
ἇ	α
Ἀ	Α
Ἁ	Α
Ἂ	Α
Ἃ	Α
Ἄ	Α
Ἅ	Α
Ἆ	Α
Ἇ	Α
ἐ	ε
ἑ	ε
ἒ	ε
ἓ	ε
ἔ	ε
ἕ	ε
Ἐ	Ε
Ἑ	Ε
Ἒ	Ε
Ἓ	Ε
Ἔ	Ε
Ἕ	Ε
ἠ	η
ἡ	η
ἢ	η
ἣ	η
ἤ	η
ἥ	η
ἦ	η
ἧ	η
Ἠ	Η
Ἡ	Η
Ἢ	Η
Ἣ	Η
Ἤ	Η
Ἥ	Η
Ἦ	Η
Ἧ	Η
ἰ	ι
ἱ	ι
ἲ	ι
ἳ	ι
ἴ	ι
ἵ	ι
ἶ	ι
ἷ	ι
Ἰ	Ι
Ἱ	Ι
Ἲ	Ι
Ἳ	Ι
Ἴ	Ι
Ἵ	Ι
Ἶ	Ι
Ἷ	Ι
ὀ	ο
ὁ	ο
ὂ	ο
ὃ	ο
ὄ	ο
ὅ	ο
Ὀ	Ο
Ὁ	Ο
Ὂ	Ο
Ὃ	Ο
Ὄ	Ο
Ὅ	Ο
ὐ	υ
ὑ	υ
ὒ	υ
ὓ	υ
ὔ	υ
ὕ	υ
ὖ	υ
ὗ	υ
Ὑ	Υ
Ὓ	Υ
Ὕ	Υ
Ὗ	Υ
ὠ	ω
ὡ	ω
ὢ	ω
ὣ	ω
ὤ	ω
ὥ	ω
ὦ	ω
ὧ	ω
Ὠ	Ω
Ὡ	Ω
Ὢ	Ω
Ὣ	Ω
Ὤ	Ω
Ὥ	Ω
Ὦ	Ω
Ὧ	Ω
ὰ	α
ά	α
ὲ	ε
έ	ε
ὴ	η
ή	η
ὶ	ι
ί	ι
ὸ	ο
ό	ο
ὺ	υ
ύ	υ
ὼ	ω
ώ	ω
ᾀ	α
ᾁ	α
ᾂ	α
ᾃ	α
ᾄ	α
ᾅ	α
ᾆ	α
ᾇ	α
ᾈ	Α	
ᾉ	Α
ᾊ	Α
ᾋ	Α
ᾌ	Α
ᾍ	Α
ᾎ	Α
ᾏ	Α
ᾐ	η
ᾑ	η
ᾒ	η
ᾓ	η
ᾔ	η
ᾕ	η
ᾖ	η
ᾗ	η
ᾘ	Η
ᾙ	Η
ᾚ	Η
ᾛ	Η
ᾜ	Η
ᾝ	Η
ᾞ	Η
ᾟ	Η
ᾠ	ω
ᾡ	ω
ᾢ	ω
ᾣ	ω
ᾤ	ω
ᾥ	ω
ᾦ	ω
ᾧ	ω
ᾨ	Ω
ᾩ	Ω
ᾪ	Ω
ᾫ	Ω
ᾬ	Ω
ᾭ	Ω
ᾮ	Ω
ᾯ	Ω
ᾰ	α
ᾱ	α
ᾲ	α
ᾳ	α
ᾴ	α
ᾶ	α
ᾷ	α
Ᾰ	Α
Ᾱ	Α
Ὰ	Α
Ά	Α
ᾼ	Α
ῂ	η
ῃ	η
ῄ	η
ῆ	η
ῇ	η
Ὲ	Ε
Έ	Ε
Ὴ	Η
Ή	Η
ῌ	Η
ῐ	ι
ῑ	ι
ῒ	ι
ΐ	ι
ῖ	ι
ῗ	ι
Ῐ	Ι	
Ῑ	Ι
Ὶ	Ι
Ί	Ι
ῠ	υ
ῡ	υ
ῢ	υ
ΰ	υ
ῦ	υ
ῧ	υ
Ῠ	Υ
Ῡ	Υ
Ὺ	Υ
Ύ	Υ
ῲ	ω
ῳ	ω
ῴ	ω
ῶ	ω
ῷ	ω
Ὸ	Ο
Ό	Ο
Ὼ	Ω
Ώ	Ω
ῼ	Ω);
%p2m=qw{ἀ	α
ἁ	α
ἂ	ά
ἃ	ά
ἄ	ά
ἅ	ά
ἆ	ά
ἇ	ά
Ἀ	Α
Ἁ	Α
Ἂ	Ά
Ἃ	Ά
Ἄ	Ά
Ἅ	Ά
Ἆ	Ά
Ἇ	Ά
ἐ	ε
ἑ	ε
ἒ	έ
ἓ	έ
ἔ	έ
ἕ	έ
Ἐ	Ε
Ἑ	Ε
Ἒ	Έ
Ἓ	Έ
Ἔ	Έ
Ἕ	Έ
ἠ	η
ἡ	η
ἢ	ή
ἣ	ή
ἤ	ή
ἥ	ή
ἦ	ή
ἧ	ή
Ἠ	Η
Ἡ	Η
Ἢ	Ή
Ἣ	Ή
Ἤ	Ή
Ἥ	Ή
Ἦ	Ή
Ἧ	Ή
ἰ	ι
ἱ	ι
ἲ	ί
ἳ	ί
ἴ	ί
ἵ	ί
ἶ	ί
ἷ	ί
Ἰ	Ι
Ἱ	Ι
Ἲ	Ί
Ἳ	Ί
Ἴ	Ί
Ἵ	Ί
Ἶ	Ί
Ἷ	Ί
ὀ	ο
ὁ	ο
ὂ	ό
ὃ	ό
ὄ	ό
ὅ	ό
Ὀ	Ο
Ὁ	Ο
Ὂ	Ό
Ὃ	Ό
Ὄ	Ό
Ὅ	Ό
ὐ	υ
ὑ	υ
ὒ	ύ
ὓ	ύ
ὔ	ύ
ὕ	ύ
ὖ	ύ
ὗ	ύ
Ὑ	Υ
Ὓ	Υ
Ὕ	Ύ
Ὗ	Ύ
ὠ	ω
ὡ	ω
ὢ	ώ
ὣ	ώ
ὤ	ώ
ὥ	ώ
ὦ	ώ
ὧ	ώ
Ὠ	Ω
Ὡ	Ω
Ὢ	Ώ
Ὣ	Ώ
Ὤ	Ώ
Ὥ	Ώ
Ὦ	Ώ
Ὧ	Ώ
ὰ	ά
ά	ά
ὲ	έ
έ	έ
ὴ	ή
ή	ή
ὶ	ί
ί	ί
ὸ	ό
ό	ό
ὺ	ύ
ύ	ύ
ὼ	ώ
ώ	ώ
ᾀ	α
ᾁ	α
ᾂ	ά
ᾃ	ά
ᾄ	ά
ᾅ	ά
ᾆ	ά
ᾇ	ά
ᾈ	Α
ᾉ	Α
ᾊ	Ά
ᾋ	Ά
ᾌ	Ά
ᾍ	Ά
ᾎ	Ά
ᾏ	Ά
ᾐ	η
ᾑ	η
ᾒ	ή
ᾓ	ή
ᾔ	ή
ᾕ	ή
ᾖ	ή
ᾗ	ή
ᾘ	Η
ᾙ	Η
ᾚ	Ή
ᾛ	Ή
ᾜ	Ή
ᾝ	Ή
ᾞ	Ή
ᾟ	Ή
ᾠ	ω
ᾡ	ω
ᾢ	ώ
ᾣ	ώ
ᾤ	ώ
ᾥ	ώ
ᾦ	ώ
ᾧ	ώ
ᾨ	Ω
ᾩ	Ω
ᾪ	Ώ
ᾫ	Ώ
ᾬ	Ώ
ᾭ	Ώ
ᾮ	Ώ
ᾯ	Ώ
ᾲ	ά
ᾳ	α
ᾴ	ά
ᾶ	ά
ᾷ	ά
Ὰ	Ά
Ά	Ά
ᾼ	Α
ῂ	ή
ῃ	η
ῄ	ή
ῆ	ή
ῇ	ή
Ὲ	Έ
Έ	Έ
Ὴ	Ή
Ή	Ή
ῌ	Η
ῒ	ΐ
ΐ	ΐ
ῖ	ί
ῗ	ΐ
ῢ	ΰ
ΰ	ΰ
ῤ	ρ
ῥ	ρ
ῦ	ύ
ῧ	ΰ
Ὺ	Ύ
Ύ	Ύ
Ῥ	Ρ
ῲ	ώ
ῳ	ω
ῴ	ώ
ῶ	ώ
ῷ	ώ
Ὸ	Ό
Ό	Ό
Ὼ	Ώ
Ώ	Ώ
ῼ	Ω
᾽   ’
᾿   ’
´   ʹ};
%direm = #dieresis removal
qw{ϊ	ι
ϋ	υ
ΐ	ί
ΰ	ύ
ῒ	ί
ῢ	ύ
ῗ	ί
ῧ	ύ};

sub poly2mono {
	if ($OLD_PERL or ! is_utf8($_[0])) {
		goto &_poly2mono;
	} else {
		decode_utf8(_poly2mono(encode_utf8($_[0]))); # Yes, I know this is inefficient. I might rewrite _poly2mono some day.
	}
}


sub _poly2mono { # the guts
	my($orig) = $_[0];
	my($newstring,$thischar);
	my($fsyl,$fphon,$lsyl,$prevvowel); # first syllable, first phoneme, last syllable, previous vowel
	my(@lexis);
	while($orig =~ s/$C//) {
		$thischar = $&;
		if ($thischar =~ /^$diacr$/) {
			# current pos
			my($cpos) = $thischar =~ /^$ui$/ && @lexis
				&&
				$lexis[$#lexis] =~ /^$diphpre$/
				? $#lexis-1
				: $#lexis;
			$fphon=$prevvowel='';
			$fsyl=$lsyl=1;
			if ($lexis[$#lexis] !~ /^$gramma$/ or !scalar @lexis or $cpos<$#lexis && 2>scalar @lexis) {
				$fphon=1;
			} else{
				foreach (reverse 0..$cpos){
					if ($lexis[$_] =~ /^$gramma$/ &&
					   $lexis[$_] !~ /^$conson$/){
						$prevvowel=$lexis[$_];
							$fsyl='';last;
					} elsif ($lexis[$_] !~ /^$gramma$/){
						last;
					}
				}
			}
			my($nnn)=0;
			my($lll);
			for(;$orig =~ /$C {$nnn}($C)/x;++$nnn){
				$lll = $1;
				if($1 =~ /^$gramma$/ &&
				   $lll !~ /^$conson$/){
					$lsyl='';last;
				}elsif($lll !~ /^$gramma$/){
					last;
				}
			}
	
			#print "$thischar ", $fphon && "fphon ", $fsyl && "fsyl ", $lsyl && 'lsyl ', "prevvowel: $prevvowel<br>";
			
			if ($thischar =~ /^$psiliaccent_lc$/ && !$fphon &&
			   (!$fsyl or !$lsyl)) {
				$newstring .=($remove{$thischar} ||
				$thischar) . ' ΄';

			# Accentuation exceptions are dealt with here:
			}elsif ($thischar eq 'ῦ' and
			   join('',@lexis) =~ /^(?:Π|π)ο$/ and 
			   $orig !~ /^$gramma/){
				$newstring .= 'ύ';
			}
			elsif ($thischar eq 'ῶ' and
			   join('',@lexis) =~ /Π|π$/ and
			   $orig =~ /^ς(?!$gramma)/) {
				$newstring .= 'ώ';
			}
			elsif ($thischar =~ /^(?:ἢ|ἤ)/ and
			   !@lexis and
			   $orig =~ /^(?!$gramma)/) {
				$newstring .= 'ή';
			}
			elsif ($thischar =~ /^(?:ὰ|ά)/ and
			   join('',@lexis) =~ /(?:Γ|γ|Π|π)ι$/ and
			   $orig =~ /^(?!$gramma)/) {
				$newstring .= 'α';
			}
			elsif ($thischar =~ /^(?:ὸ|ό)/ and
			   join('',@lexis) =~ /(?:Π|π)ι$/ and
			   $orig =~ /^(?!$gramma)/) {
				$newstring .= 'ο';
			}

			elsif (($fsyl and $lsyl) or ($prevvowel =~
			   /$accent/)){
				$newstring .= $remove{$thischar} ||
					$thischar;
			}elsif ($thischar =~ /${\join '|', keys %direm}/ && $lexis[$#lexis] !~ /^$diphpre$/ or $thischar =~ /ϊ|ΐ|ῒ|ῗ|Ϊ/ && $lexis[$#lexis] !~ /Α|Ε|Ο|Υ|α|ε|ο|υ/ or $thischar =~ /ϋ|ΰ|ῢ|ῧ|Ϋ/ && $lexis[$#lexis] !~ /Α|Ε|Η|Ο|α|ε|η|ο/){
				$newstring .= $direm{$thischar};
			} else {
				$newstring .= $p2m{$thischar}||$thischar
			}
		}
		else {$newstring .= $p2m{$thischar} || $thischar}
		if ($thischar =~ /^$gramma$/) {
			push @lexis, $thischar;
		} else { @lexis = ();}
	}
	return $newstring;
}

1;

__END__

I was going to put this in the man page, but I decided against it:

 # raw utf8 bytes:
 $mono = poly2mono
         "\xce\xa4\xce\xbf\xe1\xbd\x90\xce\xbb\xe1\xbd\xb1\xcf\x87\xce"
       . "\xb9\xcf\x83\xcf\x84\xce\xbf\xce\xbd \xce\xb8\xe1\xbd\xb3\xce"
       . "\xbb\xcf\x89 \xce\xbd\xe1\xbc\x84\xcf\x83\xcf\x84\xce\xb1\xce"
       . "\xb9 \xce\xba\xce\xb1\xce\xbb\xe1\xbd\xb1!";
 # $mono now contains
 #       "\xce\xa4\xce\xbf\xcf\x85\xce\xbb\xce\xac\xcf\x87\xce\xb9\xcf"
 #     . "\x83\xcf\x84\xce\xbf\xce\xbd \xce\xb8\xce\xad\xce\xbb\xcf\x89"
 #     . " \xce\xbd\xce\xb1 \xce\x84\xcf\x83\xcf\x84\xce\xb1\xce\xb9 "
 #     . "\xce\xba\xce\xb1\xce\xbb\xce\xac!"
 
 # OR
 
 # Unicode string:
 $mono = poly2mono
         "\x{03a4}\x{03bf}\x{1f50}\x{03bb}\x{1f71}\x{03c7}\x{03b9}"
      .  "\x{03c3}\x{03c4}\x{03bf}\x{03bd} \x{03b8}\x{1f73}\x{03bb}"
      .  "\x{03c9} \x{03bd}\x{1f04}\x{03c3}\x{03c4}\x{03b1}\x{03b9} "
      .  "\x{03ba}\x{03b1}\x{03bb}\x{1f71}!"
 # $mono now contains
 #       "\x{03a4}\x{03bf}\x{03c5}\x{03bb}\x{03ac}\x{03c7}\x{03b9}"
 #     . "\x{03c3}\x{03c4}\x{03bf}\x{03bd} \x{03b8}\x{03ad}\x{03bb}"
 #     . "\x{03c9} \x{03bd}\x{03b1} \x{0384}\x{03c3}\x{03c4}\x{03b1}"
 #     . "\x{03b9} \x{03ba}\x{03b1}\x{03bb}\x{03ac}!"




 =encoding utf-8 (no POD converter seems to support this, even though the perlpod man page has it listed)

=head1 NAME

Lingua::EL::Poly2Mono - Convert polytonic Greek to monotonic

=head1 VERSION

This document describes version .02 of
S<Lingua::EL::Poly2Mono,> released in October of 2006.

=head1 SYNOPSIS

 use Lingua::EL::Poly2Mono 'poly2mono';
 $monotonic_equivalent = poly2mono $polytonic_text;
 
 # OR
 
 use Lingua::EL::Poly2Mono;
 $monotonic_equivalent =
	Lingua::EL::Poly2Mono::poly2mono $polytonic_text;

=head1 DESCRIPTION

This module provides one exportable subroutine, C<poly2mono>, which
takes a traditional polytonic Greek string as its sole argument and
converts in to Modern monotonic. The input string can be either a
Unicode string or a sequence of raw Unicode bytes. The return value will
be in the same format.

To make this clearer:

 # Unicode string:
 $mono = poly2mono "\x{1f21}"; # eta with dasia
 # $mono now contains "\x{03b7}" (unaccented eta)

 # raw Unicode bytes:
 $mono = poly2mono "\xe1\xbc\xa1";
 # $mono now contains "\xce\xb7"

=head1 COMPATIBILITY

This module has only been tested with Perl 5.002_01
and 5.8.6 (in 5.002_01 you need parentheses around the argument or
a
S<C<use subs 'poly2mono'>> statement). It uses the Encode module's
C<is_utf8> function to distinguish
between the two types of input. If this function (or the Encode module)
is not available, the
input will be treated as bytes.

=head1 VERSION HISTORY

0.02 (October 2006, this version)
Accentuation was corrected for the words ή, για, πιο and πια.

0.01 (April 2006)
The first version

=head1 AUTHOR

Father Chrysostomos
<sprout (at]cpan.org>

=cut


