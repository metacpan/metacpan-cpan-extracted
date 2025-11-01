use strict;
use warnings;

use Hustle::Table;
use Test::More;
plan tests=>8;

my $table=Hustle::Table->new;


my %cache;

my %hit;

$table->add(
	{matcher=>"B", type=>"begin",	value=>"Entry2"},
	{matcher=>"^(A)", 		value=>"Entry1"},
);

my $dispatcher=$table->prepare_dispatcher(cache=>\%cache);

my ($value,$capture)=$dispatcher->("A");

ok keys %cache==1 , "Cache Entry added";
ok $value->[1] eq "Entry1", "Correct value";

%cache=();

ok ((keys(%cache)==0), "Cache Entry removed");

$dispatcher->("A");
($value,$capture)=$dispatcher->("A");


ok keys %cache==1 , "Cache Entry added";
ok $value->[1] eq "Entry1", "Correct value";
ok $capture->[0] eq "A", "Correct Capture";

($value,$capture)=$dispatcher->("A");
ok $value->[1] eq "Entry1", "Correct value";
ok $capture->[0] eq "A", "Correct Capture";


