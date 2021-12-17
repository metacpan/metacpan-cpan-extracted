use strict;
use warnings;

use Hustle::Table;
use Test::More;

plan  tests=>4;
my $table=Hustle::Table->new;

#add entries

$table->add({matcher=>"exact",sub=>sub { ok $_[1] eq "exact", "Exact match ok"}});

$table->add({matcher=>qr/re(g)ex/, sub=>sub { 
		ok $_[1] eq "regex", "regex match ok";
		ok $1 eq "g", "regex capture ok";
	}}
);

#set default
$table->set_default(sub { ok $_[1] eq "unmatched", "Defualt as expected"});


my $dispatcher=$table->prepare_dispatcher(type=>"online",cache=>undef);

#Execute dispatcher and tests
$dispatcher->("exact","exact");
$dispatcher->("regex","regex");
$dispatcher->("unmatched","unmatched");



