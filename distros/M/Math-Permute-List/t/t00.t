use Test::More qw(no_plan);

=pod

An important test: the code block supplied should be executed once 
according to Philipp Rumpf

=cut


use Math::Permute::List;

my $a = '';

ok 1 == permute {$a .= "1".scalar(@_)} ();

ok $a eq '10';

