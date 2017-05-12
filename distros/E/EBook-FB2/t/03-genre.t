#!perl -T

use Test::More tests => 2;
use XML::DOM;
use XML::DOM::XPath;
use EBook::FB2::Description::Genre;

my $genre_data = '<genre match="98">fiction</genre>';

my $parser = XML::DOM::Parser->new();
my $xp = $parser->parse($genre_data);
my $genre = EBook::FB2::Description::Genre->new;
my @nodes = $xp->findnodes("/genre");
$genre->load($nodes[0]);
is($genre->name, 'fiction');
is($genre->match, '98');
