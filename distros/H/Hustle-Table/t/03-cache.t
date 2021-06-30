use strict;
use warnings;

use Hustle::Table;
use Test::More;

my $table=Hustle::Table->new;


my %cache;

my %hit;
my $capture;

my $deleteFromCache=1;
$table->add(
	{matcher=>qr/^uncached/, 	sub=>sub {$hit{$_[0]}++; $deleteFromCache}},
	{matcher=>qr/^cached/, 		sub=>sub {$hit{$_[0]}++; !$deleteFromCache}},
);

my $dispatcher=$table->prepare_dispatcher(type=>"online", cache=>\%cache);

$dispatcher->("uncached");
$dispatcher->("cached");


ok ((keys(%cache)==1) and exists($cache{cached}), "Cache filtering ok");

$deleteFromCache=1;

$dispatcher->("uncached");
$dispatcher->("cached");

ok ((keys(%cache)==1) and exists($cache{uncached}), "Cache filtering ok");


done_testing;



