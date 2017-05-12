
#require Test::Harness;

use strict;
#use Test::More tests => 1;
use Test::More 'no_plan';

use GOBO::DBIC::GODBModel::Query;


## Old: Get args from the environment now, but these would be preferred.
my $query_args = {};
#$query_args->{host} ='localhost'; # or: $ENV: GO_DBHOST=localhost
#$query_args->{name} ='go';        # or: $ENV: GO_DBNAME=go
$query_args->{type} ='term_lazy';

# Only test in a defined environment.
if( ! $ENV{GO_DBNAME} || ! $ENV{GO_DBHOST} ){
  warn "Won't test without at least GO_DBNAME and GO_DBHOST set.";
}else{

  ## Constructor.
  my $q = GOBO::DBIC::GODBModel::Query->new($query_args);
  ok( defined($q), "is defined");

  ## Trivial query.
  my $all_terms = $q->get_all_results({'me.acc' => 'GO:0008150'});
  is(scalar(@$all_terms), 1, "got one for 'GO:0008150'");
  my $t = $$all_terms[0];
  is($t->name, 'biological_process', "walk out 1");

  # ## Trivial walk out.
  # my $all_terms = $q->get_all_results({'me.acc' => 'GO:43473',
  # 				     'graph_path.distance' => 1});
  # print STDERR "_n_" . scalar($all_terms) . "\n";
  
  #my @d = $t->descendents;
  #my @d = $t->ancestors;
  #print STDERR "_n_" . scalar(@d) . "\n";
  #foreach my $grp (@d){
  #  print STDERR "___s: " . $grp->subject->acc . ', o: ' . $grp->object->acc. "\n";
  #}

  ## Apparently, this isn't in the wild yet...do I have an old package?
  #done_testing();

}

