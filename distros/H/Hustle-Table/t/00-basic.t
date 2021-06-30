use strict;
use warnings;

use Hustle::Table;
use Test::More;
plan tests=>7;

#does it require ok
require_ok("Hustle::Table");

my $table=Hustle::Table->new;

ok defined $table, "New table";

# Can we make all the dispatcher types?
{
	my $dispatcher;
	$dispatcher=$table->prepare_dispatcher();
	ok(defined $dispatcher,"Online fallback dispatcher compile");
	
	$dispatcher=$table->prepare_dispatcher(type=>"online",cache=>undef);
	ok(defined $dispatcher,"Online dispatcher compile");

	$dispatcher=$table->prepare_dispatcher(type=>"online",cache=>{});
	ok(defined $dispatcher,"Online cached dispatcher compile");

	$dispatcher=$table->prepare_dispatcher(type=>"unkown");
	ok(!defined $dispatcher, "Invalid dispatcher check");

	$dispatcher=$table->prepare_dispatcher(type=>"online", cache=>[]);
	ok(!defined $dispatcher, "Invalid cache check");

}
