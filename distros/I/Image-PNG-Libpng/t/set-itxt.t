# This tests setting text in a PNG image.

use warnings;
use strict;
use utf8;
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

use FindBin '$Bin';

use Image::PNG::Const ':all';
use Image::PNG::Libpng ':all';

BEGIN: {
    use lib "$Bin";
    use IPNGLT;
};

skip_itxt ();
skip_old ();

my $file = "$Bin/set-text.png";
my $text = [
	{key => 'baba', lang => 'binkers', lang_key => 'ばば', text => 'ぶぶ',
	 compression => PNG_ITXT_COMPRESSION_NONE},
	{key => 'bobo', lang => 'bonkers', lang_key => 'ぼぼ', text => 'びび',
	 compression => PNG_ITXT_COMPRESSION_zTXt},
    ];
itxt_round_trip ($file, $text);

my $longfile = "$Bin/long-set-text.png";

# The "lang" field should be only eight bytes long, so the following
# is actually in error according to the PNG specification, but libpng
# doesn't seem to restrict the length of the language string that it
# allows, or writes, or reads.

my $longtext = [
    {lang => 'verylonglanguageindeed', key => 'bonkers', lang_key => 'binkers',
     text => 'plonkers', compression => PNG_ITXT_COMPRESSION_NONE},
];
itxt_round_trip ($longfile, $longtext);

done_testing ();
exit;

sub itxt_round_trip
{
    my ($longfile, $longtext) = @_;
    my $longpng = fake_wpng ();
    $longpng->set_text ($longtext);
    my $longcheck = round_trip ($longpng, $longfile);
    my $longcheck_text = $longcheck->get_text ();
    for my $i (0..$#$longtext) {
	my $x = $longtext->[$i];
	my $y = $longcheck_text->[$i];
	for my $k (keys %$x) {
	    ok (defined $y->{$k}, "Got key $k back for text chunk $i");
	    is ($y->{$k}, $x->{$k},
		"Value for $k is the same for text chunk $i");
	}
    }
}
