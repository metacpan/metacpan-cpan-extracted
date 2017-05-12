use strict;
use Test::More 'no_plan';

use GOBO::DBIC::GODBModel::Graph;


## Old: Get args from the environment now, but these would be preferred.
my $query_args = {};
#$query_args->{host} ='localhost'; # or: $ENV: GO_DBHOST=localhost
#$query_args->{name} ='go';        # or: $ENV: GO_DBNAME=go

# Only test in a defined environment.
if( ! $ENV{GO_DBNAME} || ! $ENV{GO_DBHOST} ){
  warn "Won't test without at least GO_DBNAME and GO_DBHOST set.";
}else{

  ## Constructor.
  my $g = GOBO::DBIC::GODBModel::Graph->new($query_args);
  ok( defined($g), "is defined");

  ## Check roots.
  my $roots = $g->get_roots();
  is(scalar(keys %$roots), 3, "got all roots");
  foreach my $r (keys %$roots){
    ok($g->is_root_p($r), $r . " is a root");
  }

}
