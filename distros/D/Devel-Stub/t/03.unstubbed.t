use Test::More tests => 3;

use lib 't/lib';
use Devel::Stub::lib;
use Foo::Bar;

# normal use

is($INC[0],'t/lib');

my $b = Foo::Bar->new;

is($b->woo,"woo!");

is($b->moo,"moo!");

