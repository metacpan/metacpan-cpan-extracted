use strict;
use warnings;
use Test::More tests => 1;
use lib 'lib';
use Forward::Routes;



#############################################################################
### nested routes naming

my $r = Forward::Routes->new;
my $hello = $r->add_route('hello');
my $world = $hello->add_route('world')->name('hello_world');

my $m = $r->match(get => 'hello/world');
is $m->[0]->name, 'hello_world';



