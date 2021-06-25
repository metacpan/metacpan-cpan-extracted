use strict;
use warnings;

use Hustle::Table;
use Test::More;

require_ok("Hustle::Table");

my $table=Hustle::Table->new;

ok defined $table, "New table";

my %cache;

my %hit;
my $capture;

my $deleteFromCache=0;
$table->add(
	{match=>qr/regexp/, sub=>sub {$hit{$_[0]}++;return $deleteFromCache}},
	{match=>qr/capture(\d+)/, sub=>sub {$hit{$_[0]}++; $capture=$1;return $deleteFromCache}},
	{match=>"exact", sub=>sub {$hit{$_[0]}++;return $deleteFromCache}},
	[undef,sub {$hit{$_[0]}++;return $deleteFromCache}, undef, undef]
);

my $dispatcher=$table->prepare_dispatcher(type=>"online", cache=>\%cache);

ok(defined($dispatcher), "Creating online dispatcher");

my @inputs=("match a regexp", "with a capture123","exact","catch all");


for my $input (@inputs){
	$dispatcher->($input);
	ok(($hit{$input}==1), "$input");
	ok defined $cache{$input},"Cached ok";
}


#Remove from cache
$deleteFromCache=1;
for my $input (@inputs){
	$dispatcher->($input);
	ok(($hit{$input}==2), "$input");
	ok !exists($cache{$input}),"Uncached OK";
}

done_testing;



