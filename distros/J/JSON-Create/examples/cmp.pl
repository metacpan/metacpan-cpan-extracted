use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use JSON::Create;
my $jc = JSON::Create->new (sort => 1, indent => 1);
$jc->cmp (\&uccmp);
my %emojis = (
    lifeforms => {
	Kingkong => '🦍',
	goat => '🐐',
	elephant => '🐘',
	Grape => '🍇',
	Watermelon => '🍉',
	melon => '🍈',
	# What if life exists based on another element? 🖖
	siliconbased => '❄',
    },
);
binmode STDOUT, ":encoding(utf8)";
print $jc->run (\%emojis);

sub uccmp
{
    my ($a, $b) = @_;
    return uc ($a) cmp uc ($b);
}
