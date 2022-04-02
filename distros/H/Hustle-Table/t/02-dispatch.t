use strict;
use warnings;

use Hustle::Table;
use Test::More;

plan  tests=>6;

my $table=Hustle::Table->new;

#add entries

$table->add({matcher=>"exact", type=>"exact", value=>sub { ok $_[0] eq "exact", "Exact match"}});

$table->add({matcher=>"start", type=>"start", value=>sub { ok $_[0] =~ /^start/, "Start match"}});

$table->add({matcher=>"end", type=>"end", value=>sub { ok $_[0] =~ /end$/, "End match"}});

$table->add({matcher=>1234, type=>"numeric", value=>sub { ok $_[0] == 1234, "Numeric match"}});

$table->add({matcher=>qr/re(g)ex/, value=>sub { 
		ok $_[0] eq "regex", "regex match";
		ok $_[1][0] eq "g", "regex capture ok";
	}}
);

#set default
$table->set_default(sub {ok $_[0] eq "unmatched", "Defualt as expected"});


my $dispatcher=$table->prepare_dispatcher();


#Execute dispatcher and tests
my ($entry,$capture);
my @inputs=(
		"exact",
		"match at the end",
		1234,
		"regex",
		"unmatched"
	);

for(@inputs){
	($entry,$capture)=$dispatcher->($_);
	$entry->[1]($_, $capture);
}



