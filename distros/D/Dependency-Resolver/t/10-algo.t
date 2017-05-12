#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use Dependency::Resolver;

#          A
#         / \
#        v   v
#        D   B
#        ^  /\
#         \v  v
#          C->E


my $a  = { name => 'A' , version => 1, deps => [ 'B == 1', 'D']};
my $b1 = { name => 'B' , version => 1, deps => [ 'C == 1', 'E'] };
my $b2 = { name => 'B' , version => 2, deps => [ 'C == 2', 'E'] };
my $b3 = { name => 'B' , version => 3, deps => [ 'C == 3', 'E'] };
my $c1 = { name => 'C' , version => 1, deps => [ 'D', 'E'] };
my $c2 = { name => 'C' , version => 2, deps => [ 'D', 'E'] };
my $c3 = { name => 'C' , version => 3, deps => [ 'D', 'E'] };
my $d  = { name => 'D' , version => 1};
my $e  = { name => 'E' , version => 1};

ok(my $resolver = Dependency::Resolver->new, 'build resolver');
ok( $resolver->add($a, $b3, $b2, $b1, $c1, $c2, $c3, $d, $e), "add nodes");

# # test get_modules
is_deeply($resolver->get_modules('B', '==', 1),  [$b1], 'get_modules B == 1');
is_deeply($resolver->get_modules('B', '>=', 1),  [$b1, $b2, $b3], 'get_modules B >= 1');
is_deeply($resolver->get_modules('B', '>=', 2),  [$b2, $b3], 'get_modules B >= 2');
is_deeply($resolver->get_modules('B', '<=', 2),  [$b1, $b2], 'get_modules B <= 2');
is_deeply($resolver->get_modules('B', '<=', 1),  [$b1], 'get_modules B <= 1');
is_deeply($resolver->get_modules('B', '<', 2),   [$b1], 'get_modules B < 2');
is_deeply($resolver->get_modules('B', '<', 1),   [], 'get_modules B < 1');

#test search_best_dep
dies_ok { $resolver->search_best_dep('F') } 'search inexistant module "F" => die';

is_deeply($resolver->search_best_dep('B == 1'), $b1, 'search_best_dep B == 1 : b1');
is_deeply($resolver->search_best_dep('B >= 1'), $b3, 'search_best_dep B => 1 : b3');
is_deeply($resolver->search_best_dep('B <= 2'), $b2, 'search_best_dep B <= 2 : b2');
is_deeply($resolver->search_best_dep('B >= 1, B<3'),        $b2, 'search_best_dep B >=1, B<3 : b2');
is_deeply($resolver->search_best_dep('B >= 1, B!=3'),       $b2, 'search_best_dep B >=1, B !=3 : b2');
is_deeply($resolver->search_best_dep('B >= 1, B<=3, B!=3'), $b2, 'search_best_dep B >= 1, B<=3, B!=3 : b2');

my $resolved = $resolver->dep_resolv($a);
is_deeply( $resolved, [ $d, $e, $c1, $b1, $a ], 'return the expected nodes [ $d, $e, $c1, $b1, $a ]');

my $a2  = { name => 'A' , version => 2, deps => [ 'B >= 2, B < 3', 'D']};
$resolved = $resolver->dep_resolv($a2);

is_deeply( $resolved, [ $d, $e, $c2, $b2, $a2 ], 'return the expected nodes [ $d, $e, $c2, $b2, $a2 ]');


my $d2  = { name => 'D' , version => 2, deps => 'B'};
$resolver->add($d2);

dies_ok { $resolver->dep_resolv($a) } 'dep_resolv die with a circular dependency';

dies_ok {$resolver->get_modules('B', '=>', 1)}  'test if operator exist';
