#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use HTML::Make;
my @colours = (
    daidai => 0xEE7800,
    murasaki => 0x884898,
    kimidori => 0xB9C42F,
    kogecha => 0x6A4D32,
    uguisuiro => 0x838B0D,
);
my $ul = HTML::Make->new ('ul');
while (@colours) {
    my $colour = shift @colours;
    my $rgb = shift @colours;
    # Here we make a new element and then push it into $ul, rather
    # than using the return value of $ul->push ().
    my $li = HTML::Make->new (
	'li', text => $colour,
	attr => {
	    style => sprintf ("background: #%06X", $rgb),
	});
    $ul->push ($li);
}
print $ul->text ();
