use Test;
BEGIN { plan tests => 2 };
use strict;
use Games::Cryptoquote;

my $quote     = 
'Omyreeohrmy jsvlrtd stpimf yjr hepnr ztpvesox yjsy yjod ztphtsx od brtu vppe!';
my $author    = q(Npn P'Mroee);

my $file = -e "t/patterns.txt" ? "t/patterns.txt" : "patterns.txt";

my $c = Games::Cryptoquote->new();

$c->build_dictionary(file => $file, type => 'patterns') or die;

$c->quote($quote);
$c->source($author);
$c->timeout(10);

$c->solve();

ok ($c->get_solution('quote') eq
    'intelligent hackers around the globe proclaim that this program is very cool!');
ok ($c->get_solution('source') eq "bob o'neill");
