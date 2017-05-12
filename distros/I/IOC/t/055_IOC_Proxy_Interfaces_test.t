#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;
use Test::Exception;

BEGIN {
    use_ok('IOC::Proxy::Interfaces');
}

{
    package IKeyable;
    
    sub get    {}
    sub set    {}
    sub keys   {}
    sub values {}
    
    package KeyableImpl;
    
    sub new {
        my ($class, %hash) = @_;
        bless \%hash => $class;
    }
    
    sub get    { (shift)->{(shift)} }
    sub set    { (shift)->{(shift)} = shift }    
    sub keys   { keys %{(shift)} }
    sub values { values %{(shift)} }
    
    sub misc_method { return 'misc_method' }
}

my $keyable = KeyableImpl->new(one => 1, two => 2, three => 3, four => 4);
isa_ok($keyable, 'KeyableImpl');
ok(!UNIVERSAL::isa($keyable, 'IKeyable'), '... keyable is not yet IKeyable');

is($keyable->misc_method(), 'misc_method', '... we can get to the misc method');

my $interface_proxy = IOC::Proxy::Interfaces->new({ interface => 'IKeyable' });
isa_ok($interface_proxy, 'IOC::Proxy::Interfaces');
isa_ok($interface_proxy, 'IOC::Proxy');

$interface_proxy->wrap($keyable);
isa_ok($keyable, 'KeyableImpl::_::Proxy');
isa_ok($keyable, 'KeyableImpl');
isa_ok($keyable, 'IKeyable');

throws_ok {
    $keyable->misc_method();
} 'IOC::MethodNotFound', '... we can no longer get to the misc method';

my $value;
lives_ok {
    $value = $keyable->get('one');    
} '... but we can get to the method which the interface allows';
cmp_ok($value, '==', 1, '... got the right value too');

my @values;
lives_ok {
    @values = $keyable->values();    
} '... but we can get to the method which the interface allows';
is_deeply(
    [ sort @values ], 
    [ 1, 2, 3, 4 ],
    '... again, we got the right values');
    
# now check the errors

throws_ok {
    IOC::Proxy::Interfaces->new({});
} 'IOC::InsufficientArguments', '... we get an error';

{
    package INothing;
    
    package NothingImpl;
    
    sub nuttin {}
}

throws_ok {
    IOC::Proxy::Interfaces->new({ interface => 'INothing' })->wrap(bless({}, 'NothingImpl'));
} 'IOC::OperationFailed', '... there are not method so we get an error';

{
    package ISomething;
    
    sub test {}
    
    package SomethingImpl;
    
    sub no_test {}
}

throws_ok {
    IOC::Proxy::Interfaces->new({ interface => 'ISomething' })->wrap(bless({}, 'SomethingImpl'));
} 'IOC::IllegalOperation', '... we get an error';
