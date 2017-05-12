use strict;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Data::Dumper;
use Graph;
#use PDL;

use_ok('Graph::Algorithm::HITS');

my $g = new Graph;
$g->add_vertices(qw/0 1 2 3 4 5/);
$g->add_edges(['1','0'], ['0','2'], ['0','4'], ['2','4'], ['4','2'], ['4','3'], ['5','4']);

my $hits = new Graph::Algorithm::HITS(graph => $g);
#print $hits->adj_matrix;
#print $hits->trans_adj;
#print $hits->trans_x_adj;
#print $hits->auth_matrix;
#print $hits->hub_matrix;
$hits->iterate(20);
#print $hits->auth_matrix;
#print $hits->hub_matrix;

my $hub = $hits->get_hub();
my @hub_ans = (qw/0.366 0.000 0.211 0.000 0.211 0.211/);
for my $v (sort keys %$hub) {
    my $a = shift @hub_ans;
    my $rounded = sprintf("%.3f", $hub->{$v});
    is($rounded, $a, 'hub elements ok');
}

my $auth = $hits->get_authority();
my @auth_ans = (qw/0.000 0.000 0.366 0.134 0.500 0.000/);
for my $v (sort keys %$auth) {
    my $a = shift @auth_ans;
    my $rounded = sprintf("%.3f", $auth->{$v});
    is($rounded, $a, 'auth elements ok');
}



done_testing;
