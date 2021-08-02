use strict;
use warnings;
use Test::More;
use lib './t';

my @argv = qw(
    --restaurant Milliways
    );

BEGIN {
    no warnings 'once';
    $App::Foo::DEFAULT_AND_ACTION = 1;
}

use App::Foo;
@argv = (my $app = App::Foo->new)->run(@argv);

is($app->{restaurant}, "Milliways at the end of universe.", "default and action (called)");
is($app->{shop}, "Pizza Hat", "default and action (not called)");

done_testing;
