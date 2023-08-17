use strict;
use warnings;

use Hustle::Table;
use Test::More;


my $table=Hustle::Table->new;

#add entries
$table->add({matcher=>"exact", type=>"exact", value=>sub { ok $_[0] eq "exact", "Exact match"}});

$table->add({matcher=>"start", type=>"start", value=>sub { ok $_[0] =~ /^start/, "Start match"}});

$table->add({matcher=>"end", type=>"end", value=>sub { ok $_[0] =~ /end$/, "End match"}});

$table->add({matcher=>1234, type=>"numeric", value=>sub { ok $_[0] == 1234, "Numeric match"}});

$table->add({matcher=>qr/re(g)(e)x/, value=>sub { 
		ok $_[0] eq "regex", "regex match";
		ok $_[1][0] eq "g", "regex capture ok";
		ok $_[1][1] eq "e", "regex capture ok";
	}}
);

$table->add({matcher=>qr/no(?:c)apture/, value=>sub { 
		ok $_[0] eq "nocapture", "regex match, no capture";
		ok $_[1]->@*==0, "zero captures"
	}}
);

$table->add({matcher=>qr/nomatched(C)*apture/, value=>sub { 
		ok $_[0] eq "nomatchedapture", "regex match, unmatched capture";
		ok $_[1]->@*==0, "zero captures";
	}}
);

my $value;
$value=sub { ok  $_[0] eq "sub", "Sub ok"; };

my $sub;
$sub=sub {
	$_[0] eq "sub" 
		and ref($_[1]) 
		and $_[1] == $value;
};

$table->add([ $sub , $value, undef]);

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
    "nocapture",
    "nomatchedapture",
		"unmatched",
		"sub",

);

for(@inputs){
	($entry, $capture)=$dispatcher->($_);
	$entry->[1]($_, $capture);
}
done_testing;
