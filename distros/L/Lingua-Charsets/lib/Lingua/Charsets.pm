package Lingua::Charsets;
{
	$Lingua::Charsets::VERSION = 0.04;
}

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

has language_charsets	=> (
	isa		=> 'HashRef',
	is		=> 'ro',
	lazy		=> 1,
	builder		=> '_build_language_charsets',
);

has language_charsets_raw_reference => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> q[
af (Afrikaans)		iso-8859-1 cp1252
sq (Albanian)		iso-8859-1 cp1252 iso-8859-16
ar (Arabic)		iso-8859-6 cp864 cp1256 MacArabic
eu (Basque)		iso-8859-1 cp1252
bg (Bulgarian)		iso-8859-5
be (Byelorussian)	iso-8859-5
ca (Catalan)		iso-8859-1 cp1252
zh (Chinese)		gb2312 big5-eten gbk euc-cn
hr (Croatian)		iso-8859-2 cp1250 MacCroatian iso-8859-16
cs (Czech)		iso-8859-2
da (Danish)		iso-8859-1 cp1252
nl (Dutch)		iso-8859-1 cp1252, iso-8859-15
en (English)		iso-8859-1 cp1252
eo (Esperanto)		iso-8859-3*
et (Estonian)		iso-8859-15 cp1257
fo (Faroese)		iso-8859-1 cp1252
fi (Finnish)		iso-8859-1 cp1252
fr (French)		iso-8859-1 cp1252
gl (Galician)		iso-8859-1 cp1252
de (German)		iso-8859-1 cp1252
ka (Georgian)		geostd8
el (Greek)		iso-8859-7 cp869 cp1253 MacGreek
iw (Hebrew)		iso-8859-8 cp1255 MacHebrew
hu (Hungarian)		iso-8859-2 cp1250 iso-8859-16
is (Icelandic)		iso-8859-1 cp1252 MacIceland iso-8859-10
id (Indonesian)		iso-8859-1
ga (Irish)		iso-8859-1 cp1252
it (Italian)		iso-8859-1 cp1252
ja (Japanese)		shiftjis iso-2022-jp euc-jp 7bit-jis iso-2022-jp-1 MacJapanese cp932 jis0201-raw jis0208-raw jis0212-raw
ko (Korean)		euc-kr ksc5601-raw cp949 MacKorean johab iso-2022-kr
lv (Latvian)		iso-8859-13 cp1257
lt (Lithuanian)		iso-8859-13 cp1257
mk (Macedonian)		iso-8859-5 cp1251
mt (Maltese)		iso-8859-3*
no (Norwegian)		iso-8859-1 cp1252
pl (Polish)		iso-8859-2 cp852 cp1250 iso-8859-13 iso-8859-16
pt (Portuguese)		iso-8859-1 cp1252
ro (Romanian)		iso-8859-2 MacRomania
ru (Russian)		koi8-r cp1251 cp866 iso-8859-5 x-mac-cyrillic
gd (Scottish)		iso-8859-1 cp1252
sr (Serbian cyrillic)	cp1251 iso-8859-5***
sr (Serbian latin)	iso-8859-2 cp1250
sk (Slovak)		iso-8859-2
sl (Slovenian)		iso-8859-2 cp1250
es (Spanish)		iso-8859-1 cp1252
sv (Swedish)		iso-8859-1 cp1252
th (Thai)		cp874 tis-620 MacThai iso-8859-11
tr (Turkish)		iso-8859-9 cp857 cp1254 MacTurkish
uk (Ukrainian)		iso-8859-5
vi (Vietnamese)		cp1258
]
);

no Moose;

sub charsets_for {
	my ($self,$lang) = @_;
	my $charsets
		= $lang
		? $self->language_charsets->{ $lang }{ charsets } || []
		: [];
}

sub _build_language_charsets {
	my $self	= shift;
	my $dict	= {};
	my $data	= $self->language_charsets_raw_reference;
	my @lines	= split /\n/, $data||'';
	for my $line ( @lines ) {
		next unless $line = join ' ', split ' ', $line||'';
		$line		=~ s|\([^\(\)]+\)| |g;
		$line		=~ s|\*||g;
		my @parts	= split ' ', $line;
		my $lang	= shift @parts;
		if ( $lang	=~ m|\A[a-z]{2}\Z| && @parts ) {
			push @{ $dict->{ $lang }{charsets} }, @parts;
		}
	}
	return $dict;
}

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: Language-based charset reference

=head1 NAME

Lingua::Charsets - Provides a list of charsets by language.

=head1 SYNOPSIS

    use Lingua::Charsets;

	my $lc = Lingua::Charsets->new;

	my $zh_charsets = $lc->charsets_for( 'zh' );

=head1 DESCRIPTION

This module provides a listing of charsets by language. It can be used
in conjunction with a charset guessing algorithm such as Encode::Guess.

The data used comes from a variety of locations; however, the initial
source was The W3C charset listing available at:

L<http://www.w3.org/International/O-charset-lang.html>

=head1 METHODS

=head2 language_charsets

Returns a HashRef consisting of ISO-639-1 language codes as hashref keys.
The hashref values are hashrefs with the key 'charsets' that consists
of an arrayref of charsets.

=head2 charsets_for( $iso_639_1_code )

Returns an ArrayRef[Str] of charsets for the language's ISO-639-1 code. An
empty ArrayRef is returned if the language isn't found.

=head1 SEE ALSO

L<Encode::Guess>, L<Encode::JP>, L<Encode::KR>, L<Lingua::RU::Charset>

=head1 REFERENCES

W3.org "I18N languages, countries and character sets" page at:

L<http://www.w3.org/International/O-charset-lang.html>

Additional information can be found at:

L<http://aspell.net/charsets/>

L<http://en.wikipedia.org/wiki/Character_encoding>

L<http://www.mnogosearch.org/doc/msearch-international.html>

Aliases are listed in the mnoGoSearch webpage; however, they are not
currently included as aliases would not be useful for decoding.
They may be added as a separate reference in the future if they are
deemed useful.

=head1 AUTHOR

John Wang E<lt>johncwang@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2013 by John Wang E<lt>johncwang@gmail.comE<gt>.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut