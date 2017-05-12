use warnings;
use strict;
use Test::More;
use Image::PNG::Libpng ':all';
use Image::PNG::Const ':all';

if (! libpng_supports ('iTXt') ||
    ! libpng_supports ('zTXt') ||
    ! libpng_supports ('tEXt')) {
    plan skip_all => 'libpng has no iTXt/zTXt/tEXt',
}

use utf8;
use FindBin;
use Scalar::Util 'looks_like_number';
binmode STDOUT, ":utf8";
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my @stuff = (
{
file => 'ct0n0g04',
comment => 'no textual data',
empty => 1,
},
{
file => 'ct1n0g04',
comment => 'with textual data',
chunks => [
{
lang => undef,
itxt_length => 0,
text_length => 8,
text => 'PngSuite',
lang_key => undef,
compression => -1,
key => 'Title',
},
{
key => 'Author',
itxt_length => 0,
text_length => 42,
lang_key => undef,
compression => -1,
text => 'Willem A.J. van Schaik
(willem@schaik.com)',
lang => undef,
},
{
lang => undef,
lang_key => undef,
compression => -1,
text => 'Copyright Willem van Schaik, Singapore 1995-96',
text_length => 46,
itxt_length => 0,
key => 'Copyright',
},
{
lang_key => undef,
text => 'A compilation of a set of images created to test the
various color-types of the PNG format. Included are
black&white, color, paletted, with alpha channel, with
transparency formats. All bit-depths allowed according
to the spec are present.',
compression => -1,
text_length => 239,
itxt_length => 0,
lang => undef,
key => 'Description',
},
{
key => 'Software',
text_length => 48,
itxt_length => 0,
lang_key => undef,
text => 'Created on a NeXTstation color using "pnmtopng".',
compression => -1,
lang => undef,
},
{
key => 'Disclaimer',
compression => -1,
lang_key => undef,
text => 'Freeware.',
text_length => 9,
itxt_length => 0,
lang => undef,
},
],
},
{
file => 'ctzn0g04',
comment => 'with compressed textual data',
chunks => [
{
key => 'Title',
lang => undef,
text => 'PngSuite',
lang_key => undef,
compression => -1,
text_length => 8,
itxt_length => 0,
},
{
key => 'Author',
itxt_length => 0,
text_length => 42,
compression => -1,
lang_key => undef,
text => 'Willem A.J. van Schaik
(willem@schaik.com)',
lang => undef,
},
{
key => 'Copyright',
lang => undef,
text_length => 46,
itxt_length => 0,
lang_key => undef,
text => 'Copyright Willem van Schaik, Singapore 1995-96',
compression => 0,
},
{
key => 'Description',
lang_key => undef,
text => 'A compilation of a set of images created to test the
various color-types of the PNG format. Included are
black&white, color, paletted, with alpha channel, with
transparency formats. All bit-depths allowed according
to the spec are present.',
compression => 0,
itxt_length => 0,
text_length => 239,
lang => undef,
},
{
lang => undef,
compression => 0,
lang_key => undef,
text => 'Created on a NeXTstation color using "pnmtopng".',
text_length => 48,
itxt_length => 0,
key => 'Software',
},
{
lang_key => undef,
text => 'Freeware.',
compression => 0,
itxt_length => 0,
text_length => 9,
lang => undef,
key => 'Disclaimer',
},
],
},
{
file => 'cten0g04',
comment => 'english',
chunks => [
{
lang => 'en',
text => 'PngSuite',
lang_key => 'Title',
compression => 1,
itxt_length => 8,
text_length => 0,
key => 'Title',
},
{
key => 'Author',
lang => 'en',
lang_key => 'Author',
text => 'Willem van Schaik (willem@schaik.com)',
compression => 1,
text_length => 0,
itxt_length => 37,
},
{
key => 'Copyright',
itxt_length => 40,
text_length => 0,
lang_key => 'Copyright',
compression => 1,
text => 'Copyright Willem van Schaik, Canada 2011',
lang => 'en',
},
{
itxt_length => 239,
text_length => 0,
lang_key => 'Description',
compression => 1,
text => 'A compilation of a set of images created to test the various color-types of the PNG format. Included are black&white, color, paletted, with alpha channel, with transparency formats. All bit-depths allowed according to the spec are present.',
lang => 'en',
key => 'Description',
},
{
lang => 'en',
lang_key => 'Software',
compression => 1,
text => 'Created on a NeXTstation color using "pnmtopng".',
itxt_length => 48,
text_length => 0,
key => 'Software',
},
{
key => 'Disclaimer',
itxt_length => 9,
text_length => 0,
lang_key => 'Disclaimer',
text => 'Freeware.',
compression => 1,
lang => 'en',
},
],
},
{
file => 'ctfn0g04',
comment => 'finnish',
chunks => [
{
key => 'Title',
lang_key => 'Otsikko',
compression => 1,
text => 'PngSuite',
itxt_length => 8,
text_length => 0,
lang => 'fi',
},
{
key => 'Author',
lang => 'fi',
itxt_length => 37,
text_length => 0,
lang_key => 'Tekijä',
compression => 1,
text => 'Willem van Schaik (willem@schaik.com)',
},
{
lang => 'fi',
itxt_length => 40,
text_length => 0,
lang_key => 'Tekijänoikeudet',
compression => 1,
text => 'Copyright Willem van Schaik, Kanada 2011',
key => 'Copyright',
},
{
key => 'Description',
text_length => 0,
itxt_length => 211,
text => 'kokoelma joukon kuvia luotu testata eri väri-tyyppisiä PNG-muodossa. Mukana on mustavalkoinen, väri, paletted, alpha-kanava, avoimuuden muodossa. Kaikki bit-syvyydessä mukaan sallittua spec on ​​läsnä.',
lang_key => 'Kuvaus',
compression => 1,
lang => 'fi',
},
{
lang => 'fi',
itxt_length => 37,
text_length => 0,
text => 'Luotu NeXTstation väriä "pnmtopng".',
lang_key => 'Ohjelmistot',
compression => 1,
key => 'Software',
},
{
key => 'Disclaimer',
lang => 'fi',
itxt_length => 9,
text_length => 0,
compression => 1,
lang_key => 'Vastuuvapauslauseke',
text => 'Freeware.',
},
],
},
{
file => 'ctgn0g04',
comment => 'greek',
chunks => [
{
key => 'Title',
itxt_length => 8,
text_length => 0,
text => 'PngSuite',
lang_key => 'Τίτλος',
compression => 1,
lang => 'el',
},
{
text_length => 0,
itxt_length => 37,
lang_key => 'Συγγραφέας',
text => 'Willem van Schaik (willem@schaik.com)',
compression => 1,
lang => 'el',
key => 'Author',
},
{
lang_key => 'Πνευματικά δικαιώματα',
text => 'Πνευματικά δικαιώματα Schaik van Willem, Καναδάς 2011',
compression => 1,
itxt_length => 80,
text_length => 0,
lang => 'el',
key => 'Copyright',
},
{
lang => 'el',
text => 'Μια συλλογή από ένα σύνολο εικόνων που δημιουργήθηκαν για τη δοκιμή των διαφόρων χρωμάτων-τύπων του μορφή PNG. Περιλαμβάνονται οι ασπρόμαυρες, χρώμα, paletted, με άλφα κανάλι, με μορφές της διαφάνειας. Όλοι λίγο-βάθη επιτρέπεται σύμφωνα με το spec είναι παρόντες.',
lang_key => 'Περιγραφή',
compression => 1,
itxt_length => 465,
text_length => 0,
key => 'Description',
},
{
text_length => 0,
itxt_length => 104,
lang_key => 'Λογισμικό',
text => 'Δημιουργήθηκε σε ένα χρώμα NeXTstation χρησιμοποιώντας "pnmtopng".',
compression => 1,
lang => 'el',
key => 'Software',
},
{
key => 'Disclaimer',
text => 'Δωρεάν λογισμικό.',
lang_key => 'Αποποίηση',
compression => 1,
itxt_length => 32,
text_length => 0,
lang => 'el',
},
],
},
{
file => 'cthn0g04',
comment => 'hindi',
chunks => [
{
key => 'Title',
text_length => 0,
itxt_length => 8,
lang_key => 'शीर्षक',
text => 'PngSuite',
compression => 1,
lang => 'hi',
},
{
key => 'Author',
lang => 'hi',
text => 'Willem van Schaik (willem@schaik.com)',
lang_key => 'लेखक',
compression => 1,
text_length => 0,
itxt_length => 37,
},
{
lang_key => 'कॉपीराइट',
text => 'कॉपीराइट Willem van Schaik, 2011 कनाडा',
compression => 1,
itxt_length => 64,
text_length => 0,
lang => 'hi',
key => 'Copyright',
},
{
key => 'Description',
lang => 'hi',
lang_key => 'विवरण',
text => 'करने के लिए PNG प्रारूप के विभिन्न रंग प्रकार परीक्षण बनाया छवियों का एक सेट का एक संकलन. शामिल काले और सफेद, रंग, पैलेटेड हैं, अल्फा चैनल के साथ पारदर्शिता स्वरूपों के साथ. सभी बिट गहराई कल्पना के अनुसार की अनुमति दी मौजूद हैं.',
compression => 1,
text_length => 0,
itxt_length => 580,
},
{
text_length => 0,
itxt_length => 103,
text => 'एक NeXTstation "pnmtopng \'का उपयोग कर रंग पर बनाया गया.',
lang_key => 'सॉफ्टवेयर',
compression => 1,
lang => 'hi',
key => 'Software',
},
{
lang => 'hi',
text_length => 0,
itxt_length => 25,
lang_key => 'अस्वीकरण',
compression => 1,
text => 'फ्रीवेयर.',
key => 'Disclaimer',
},
],
},
{
file => 'ctjn0g04',
comment => 'japanese',
chunks => [
{
key => 'Title',
itxt_length => 8,
text_length => 0,
text => 'PngSuite',
lang_key => 'タイトル',
compression => 1,
lang => 'ja',
},
{
key => 'Author',
compression => 1,
lang_key => '著者',
text => 'Willem van Schaik (willem@schaik.com)',
itxt_length => 37,
text_length => 0,
lang => 'ja',
},
{
lang => 'ja',
itxt_length => 58,
text_length => 0,
text => '著作権ウィレムヴァンシャイク、カナダ2011',
lang_key => '本文へ',
compression => 1,
key => 'Copyright',
},
{
lang_key => '概要',
text => 'PNG形式の様々な色の種類をテストするために作成されたイメージのセットのコンパイル。含まれているのは透明度のフォーマットで、アルファチャネルを持つ、白黒、カラー、パレットです。すべてのビット深度が存在している仕様に従ったことができました。',
compression => 1,
itxt_length => 351,
text_length => 0,
lang => 'ja',
key => 'Description',
},
{
lang => 'ja',
text => '"pnmtopng"を使用してNeXTstation色上に作成されます。',
lang_key => 'ソフトウェア',
compression => 1,
itxt_length => 66,
text_length => 0,
key => 'Software',
},
{
itxt_length => 21,
text_length => 0,
lang_key => '免責事項',
text => 'フリーウェア。',
compression => 1,
lang => 'ja',
key => 'Disclaimer',
},
],
},
);

# There are some instances of libpngs which return 2 for the text
# compression. However, this does not occur in any of the examples, so
# it seems like there must be a faulty libpng.

for my $test (@stuff) {
    my $png = read_png_file ("$FindBin::Bin/libpng/$test->{file}.png");
    my $texts = $png->get_text ();
    if ($texts) {
	for my $text (@$texts) {
	    if ($text->{compression} == 2) {

		# There are no examples with compression = 2 in the
		# examples anywhere, so how this happens I don't know,
		# but it does:

		# http://www.cpantesters.org/cpan/report/717bf5a4-8284-11e3-bd14-e3bee4621ba3

		plan skip_all => 'Bad compression value detected, your libpng is faulty';
		goto end;
	    }
	}
    }
}

for my $test (@stuff) {
    my $png = read_png_file ("$FindBin::Bin/libpng/$test->{file}.png");
    my $texts = $png->get_text ();
    if ($test->{empty}) {
	ok (! $texts, "no text chunks for empty");
    }
    else {
	my $chunks = $test->{chunks};
	is_deeply ($texts, $chunks, "Got expected stuff");
    }
}

# Escape route for broken libpngs.

end:

done_testing ();

# Local variables:
# mode: perl
# End:
