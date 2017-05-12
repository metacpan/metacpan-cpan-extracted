#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 43;
use Test::Exception;

use JSON::RPC::Common::Procedure::Call;

BEGIN {
    use_ok('JSORB');
    use_ok('JSORB::Dispatcher::Path');
    use_ok('JSORB::Reflector::Class');    
}

{
    package My::Point;
    use Moose;
    
    has [ 'x', 'y' ] => (
        is      => 'rw',
        isa     => 'Int',   
    );
    
    sub clear {
        my $self = shift;
        $self->x(0);
        $self->y(0);
        return;        
    }
    
    package My::Point3D;
    use Moose;
    
    extends 'My::Point';
    
    has 'z' => (
        is      => 'rw',
        isa     => 'Int',   
    );
    
    after 'clear' => sub {
        (shift)->z(0);
    };
}

my $reflector = JSORB::Reflector::Class->new(introspector => My::Point3D->meta);
isa_ok($reflector, 'JSORB::Reflector::Class');

my $ns = $reflector->namespace;
isa_ok($ns, 'JSORB::Namespace');

my $d = JSORB::Dispatcher::Path->new_with_traits(
    traits    => [ 'JSORB::Dispatcher::Traits::WithInvocant' ],
    namespace => $ns,
);
isa_ok($d, 'JSORB::Dispatcher::Path');

my $point = My::Point3D->new(x => 10, z => 20);
isa_ok($point, 'My::Point3D');

{
    my $call = JSON::RPC::Common::Procedure::Call->new(
        method => "/my/point3d/x",
        params => [],
    );
    
    my $res = $d->handler($call, $point);
    isa_ok($res, 'JSON::RPC::Common::Procedure::Return');

    ok($res->has_result, '... we have a result, not an error');
    ok(!$res->has_error, '... we have a result, not an error');

    is($res->result, 10, '... got the result we expected');
}

is($point->x, 10, '... our object has been queried successfully');

{
    my $call = JSON::RPC::Common::Procedure::Call->new(
        method => "/my/point3d/z",
        params => [],
    );
    
    my $res = $d->handler($call, $point);
    isa_ok($res, 'JSON::RPC::Common::Procedure::Return');

    ok($res->has_result, '... we have a result, not an error');
    ok(!$res->has_error, '... we have a result, not an error');

    is($res->result, 20, '... got the result we expected');
}

is($point->z, 20, '... our object has been queried successfully');

{
    my $call = JSON::RPC::Common::Procedure::Call->new(
        method => "/my/point3d/x",
        params => [100],
    );
    
    my $res = $d->handler($call, $point);
    isa_ok($res, 'JSON::RPC::Common::Procedure::Return');

    ok($res->has_result, '... we have a result, not an error');
    ok(!$res->has_error, '... we have a result, not an error');

    is($res->result, 100, '... got the result we expected');
}

is($point->x, 100, '... our object has been altered successfully');

{
    my $call = JSON::RPC::Common::Procedure::Call->new(
        method => "/my/point3d/z",
        params => [200],
    );
    
    my $res = $d->handler($call, $point);
    isa_ok($res, 'JSON::RPC::Common::Procedure::Return');

    ok($res->has_result, '... we have a result, not an error');
    ok(!$res->has_error, '... we have a result, not an error');

    is($res->result, 200, '... got the result we expected');
}

is($point->z, 200, '... our object has been altered successfully');

{
    my $call = JSON::RPC::Common::Procedure::Call->new(
        method => "/my/point3d/y",
        params => [200],
    );
    
    my $res = $d->handler($call, $point);
    isa_ok($res, 'JSON::RPC::Common::Procedure::Return');

    ok($res->has_result, '... we have a result, not an error');
    ok(!$res->has_error, '... we have a result, not an error');

    is($res->result, 200, '... got the result we expected');
}

is($point->y, 200, '... our object has been altered successfully');

{
    my $call = JSON::RPC::Common::Procedure::Call->new(
        method => "/my/point3d/isa",
        params => ['My::Point'],
    );
    
    my $res = $d->handler($call, $point);
    isa_ok($res, 'JSON::RPC::Common::Procedure::Return');

    ok(!$res->has_result, '... we have a result, not an error');
    ok($res->has_error, '... we have a result, not an error');

    like($res->error->message, qr/Could not find method \/my\/point3d\/isa/, '... got the right error');
}

{
    my $call = JSON::RPC::Common::Procedure::Call->new(
        method => "/my/point3d/clear",
        params => [],
    );
    
    my $res = $d->handler($call, $point);
    isa_ok($res, 'JSON::RPC::Common::Procedure::Return');

    ok($res->has_result, '... we have a result, not an error');
    ok(!$res->has_error, '... we have a result, not an error');

    is($res->result, undef, '... got the result we expected');
}

is($point->x, 0, '... our object has been altered successfully');
is($point->y, 0, '... our object has been altered successfully');
is($point->z, 0, '... our object has been altered successfully');



