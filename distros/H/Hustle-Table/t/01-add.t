use strict;
use warnings;

use Hustle::Table;
use Test::More;

plan  tests=>6;
my $table=Hustle::Table->new;

#add entries
ok eval {
	my @id=$table->add({matcher=>"a",value=>sub {}});
	1;
}, "Added via hash ref";

ok eval {
	my @id=$table->add(["b",sub {},undef]);
	1;
}, "Added via array ref";


ok eval {
	my @id=$table->add(matcher=>"c",value=>sub {});
	1;
}, "Added single entry";

ok eval {
	my @id=$table->add("c"=>sub {});
	1;
}, "Added simple pair entry";

ok eval {
	my @id=$table->add(
		["d",sub {},"exact"],
		{matcher=>"e", value=>sub {}},
		matcher=>"f", value=>sub{}
	);
	1;
}, "Added multiple entries";

ok eval {
	my $id=$table->add(
		["g",sub {},"exact",],
		{matcher=>"h", value=>sub {}}
	);
	1;
}


