use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use JSON::Create;
my $jc = JSON::Create->new ();
$jc->sort (1);
$jc->indent (1);
my %emojis = (
    animals => {
	kingkong => '🦍',
	goat => '🐐',
	elephant => '🐘',
    },
    fruit => {
	grape => '🍇',
	watermelon => '🍉',
	melon => '🍈',
    },
    baka => { # Japanese words
	'ば' => 'か',
	'あ' => 'ほ',
	'ま' => 'ぬけ',
    },
    moons => { # These numbers don't mean anything!
	'🌑' => 0,
	'🌒' => 0.25,
	'🌓' => 0.5,
	'🌔' => 0.75,
	'🌕' => 1,
	'🌖' => -0.25,
	'🌗' => -0.5,
	'🌘' => -0.75,
    },
);
my $out;
my $ok = eval {
    $out = $jc->create (\%emojis);
    1;
};
ok ($ok, "Eval finished OK");
my $expect = <<EOF;
{
	"animals":{
		"elephant":"🐘",
		"goat":"🐐",
		"kingkong":"🦍"
	},
	"baka":{
		"あ":"ほ",
		"ば":"か",
		"ま":"ぬけ"
	},
	"fruit":{
		"grape":"🍇",
		"melon":"🍈",
		"watermelon":"🍉"
	},
	"moons":{
		"🌑":0,
		"🌒":0.25,
		"🌓":0.5,
		"🌔":0.75,
		"🌕":1,
		"🌖":-0.25,
		"🌗":-0.5,
		"🌘":-0.75
	}
}
EOF
is ($out, $expect, "Got expected value");

my $jc_options = JSON::Create->new (sort => 1, indent => 1);
my $out_options = $jc_options->create (\%emojis);
is ($out_options, $expect, "Got expected value with options");

my $jc_set = JSON::Create->new ();
$jc_set->set (sort => 1, indent => 1);
my $out_set = $jc_set->create (\%emojis);
is ($out_set, $expect, "Got expected value with set");

done_testing ();
