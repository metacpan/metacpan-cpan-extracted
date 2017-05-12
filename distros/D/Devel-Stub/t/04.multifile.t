BEGIN {
    $ENV{APP_ENV} = "local";
}

use strict;
use Test::More;
use lib 't/lib';
use Devel::Stub::lib 
      active_if => ($ENV{APP_ENV} eq 'local'), path => "t/stub";
use Foo::Bar;
use Foo::Zoo;

subtest "stub 2 modules" => sub{
    my $b = Foo::Bar->new;
    is($b->woo,"oh!");

    my $zoo = Foo::Zoo->new();
    is $zoo->zoo,1;
};

done_testing;

