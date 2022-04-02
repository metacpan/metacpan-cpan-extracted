use strict;
use warnings;

use Hustle::Table;
use Test::More;
plan tests=>3;

#does it require ok
require_ok("Hustle::Table");

my $table=Hustle::Table->new;

ok defined $table, "New table";

{
	my $dispatcher;
	$dispatcher=$table->prepare_dispatcher();
	ok(defined $dispatcher,"Dispatcher compiled");


}
