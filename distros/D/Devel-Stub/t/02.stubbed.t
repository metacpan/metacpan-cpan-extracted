use strict;
use Test::More tests => 3;

BEGIN {
    $ENV{STUB} = 1;
}

use lib 't/lib';
use Devel::Stub::lib active_if => $ENV{STUB}, path => "t/stub";
use Foo::Bar;

is($INC[0],'t/stub');

my $b = Foo::Bar->new;

is($b->woo,"oh!");

is($b->moo,"moo!");

