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
$jc->cmp (\&uccmp);

my %emojis = (
    animals => {
	Kingkong => '🦍',
	goat => '🐐',
	elephant => '🐘',
	Grape => '🍇',
	Watermelon => '🍉',
	melon => '🍈',
    },
);
my $out;
my $ok = eval {
    $out = $jc->run (\%emojis);
    1;
};
print "$@\n";
ok ($ok, "Eval finished OK");
my $expect = <<EOF;
{
	"animals":{
		"elephant":"🐘",
		"goat":"🐐",
		"Grape":"🍇",
		"Kingkong":"🦍",
		"melon":"🍈",
		"Watermelon":"🍉"
	}
}
EOF
is ($out, $expect, "Got expected value");
done_testing ();
exit;

sub uccmp
{
    my ($a, $b) = @_;
    return uc ($a) cmp uc ($b);
}
