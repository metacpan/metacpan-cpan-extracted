# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################


use Test::More;
BEGIN { plan tests => 2 };
use_ok( Maypole::View::Mason);
my $view=Maypole::View::Mason->new();
isa_ok($view,'Maypole::View::Mason');

