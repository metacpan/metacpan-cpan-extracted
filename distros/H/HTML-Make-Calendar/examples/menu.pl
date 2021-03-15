#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use HTML::Make::Calendar 'calendar';
binmode STDOUT, ":encoding(utf8)";
my @foods = split '', <<EOF;
🍇🍈🍉🍊🍋🍌🍍🥭🍎🍏🍐🍑🍒🍓🥝🍅🥝
🍅🥒🥬🥦🧄🧅🍄🥜🌰🍘🍙🍚🍛🍜🍝🍠🍢
🍣🍤🍥🥮🍡🥟🥠🥡🦪🍦🍧🍨🍩🍪🎂🍰🧁
EOF
@foods = grep {!/\s/} @foods;
my $cal = calendar (cdata => \@foods, dayc => \&add_food);
print $cal->text ();
exit;

sub add_food
{
    my ($foods, $date, $element) = @_;
    my $today = 
    $element->push ('span', text => $date->{dom});
    my $menu = HTML::Make->new ('ol');
    for (1..3) {
	my $food = $foods->[int (rand (@$foods))];
	$menu->push ('li', text => $food);
    }
    $element->push ($menu);
}
