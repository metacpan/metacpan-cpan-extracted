#!perl

use utf8;
use Test::Most;
use MAD::Loader qw{ load_and_new };

use lib 't/lib';

my $prefix = 'Foo::Bar';
my $module = '1';
my $args   = 123;
my $method = 'foo';

my $object = load_and_new(
    module => $module,
    prefix => $prefix,
    args   => [$args],
);

isa_ok $object, "$prefix\::$module";
can_ok $object, $method;
is $object->$method(), $args, 'Build with args';

done_testing;

