use strict;
use warnings;
use Test::More;
use Graph::RandomPath;
use Graph;
use Graph::Directed;

my $tests = 0;

for my $class(qw/Graph Graph::Directed/) {
  for (1 .. 20) {
    my $g = $class->random_graph(
      vertices => int(rand(32)),
#      edges_fill => 1/(1+int(rand(10)))
    );
    my $v1 = $g->random_vertex;

    redo unless defined $v1;

    my @s = $g->all_successors($v1);
    redo unless @s;
    my $v2 = $s[rand @s];
    eval {
      my $gen = Graph::RandomPath
          ->create_generator($g, $v1, $v2, max_length => 32);
      for (1 .. 10) {
        ok($g->has_path($gen->()));
        $tests++;
      }
    };
    if ($@) {
      # ...
    }
  }
}

done_testing($tests);
