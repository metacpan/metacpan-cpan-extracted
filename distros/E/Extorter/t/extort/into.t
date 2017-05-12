package Test::Package::A;
package Test::Package::B; sub example { 123 }
package main;

use Test::More;

use_ok 'Extorter';
can_ok 'extort', 'into';

my $package = 'Test::Package::A';
ok ! $package->can('carp');
ok ! $package->can('croak');
ok ! $package->can('example');

$package->extort::into($package, 'Carp::carp');
$package->extort::into($package, 'Carp::croak');
$package->extort::into($package, 'Test::Package::B::example');

ok $package->can('carp');
ok $package->can('croak');
ok $package->can('example');

is $package->example, 123;

done_testing;
