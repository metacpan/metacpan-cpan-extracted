use strict;
use warnings;

use Hustle::Table;
use Test::More;

plan  tests=>12;
my $table=Hustle::Table->new;

#add entries
ok eval {
	my @id=$table->add({matcher=>"a",sub=>sub {}});
	ok $id[0] == 0, "Unique id => $id[0]";
	1;
}, "Added via hash ref";

ok eval {
	my @id=$table->add(["b",sub {},undef,undef]);
	ok $id[0]== 1, "Unique id => $id[0]";
	1;
}, "Added via array ref";

ok eval {
	my @id=$table->add(matcher=>"c",sub=>sub {});
	ok $id[0] ==2, "Unique id => $id[0]";
	1;
}, "Added single entry";

ok eval {
	my @id=$table->add(
		["d",sub {},"label",undef],
		{matcher=>"e", sub=>sub {}},
		matcher=>"f", sub=>sub{}
	);
	ok @id ==3, "Added three entries @id";
	ok $id[0] eq "label", "User supplied label => $id[0]";
	ok $id[1] == 3 ,"Unique id => $id[1]";
	ok $id[2] == 4 ,"Unique id => $id[1]";

	1;
}, "Added multiple entries";

{
	my $id=$table->add(
		["g",sub {},"label",undef],
		{matcher=>"h", sub=>sub {}}
	);
	ok $id ==2 , "Scalar added count";
}


