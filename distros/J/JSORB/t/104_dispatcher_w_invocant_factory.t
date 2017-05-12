#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 20;
use Test::Exception;

use JSON::RPC::Common::Procedure::Call;

BEGIN {
    use_ok('JSORB');
    use_ok('JSORB::Dispatcher::Path');
}

{
    package App::Foo;
    use Moose;
    
    has 'bar' => (
        is      => 'ro',
        isa     => 'Str',   
        default => sub { "BAR" },
    );
    
    has 'baz' => (
        is      => 'ro',
        isa     => 'Str',   
        default => sub { "BAZ" },
    );    
}

my $ns = JSORB::Namespace->new(
    name     => 'App',
    elements => [
        JSORB::Interface->new(
            name       => 'Foo',            
            procedures => [
                JSORB::Method->new(
                    name  => 'bar',
                    spec  => [ 'Unit' => 'Str' ],
                ),
                JSORB::Method->new(
                    name  => 'baz',
                    spec  => [ 'Unit' => 'Str' ],
                ),                                                              
            ]
        )            
    ]
);
isa_ok($ns, 'JSORB::Namespace');

my $d = JSORB::Dispatcher::Path->new_with_traits(
    traits    => [ 'JSORB::Dispatcher::Traits::WithInvocantFactory' ],
    namespace => $ns,
);
isa_ok($d, 'JSORB::Dispatcher::Path');

{
    my $call = JSON::RPC::Common::Procedure::Call->new(
        method => "/app/foo/bar",
        params => [],
    );
    
    my $res = $d->handler($call);
    isa_ok($res, 'JSON::RPC::Common::Procedure::Return');

    ok($res->has_result, '... we have a result, not an error');
    ok(!$res->has_error, '... we have a result, not an error');

    is($res->result, 'BAR', '... got the result we expected');
}

{
    my $call = JSON::RPC::Common::Procedure::Call->new(
        method => "/app/foo/baz",
        params => [],
    );
    
    my $res = $d->handler($call);
    isa_ok($res, 'JSON::RPC::Common::Procedure::Return');

    ok($res->has_result, '... we have a result, not an error');
    ok(!$res->has_error, '... we have a result, not an error');

    is($res->result, 'BAZ', '... got the result we expected');
}

{
    my $call = JSON::RPC::Common::Procedure::Call->new(
        method => "/app/foo/bar",
        params => [],
    );
    
    my $res = $d->handler($call, bar => 'This is a BAR');
    isa_ok($res, 'JSON::RPC::Common::Procedure::Return');

    ok($res->has_result, '... we have a result, not an error');
    ok(!$res->has_error, '... we have a result, not an error');

    is($res->result, 'This is a BAR', '... got the result we expected');
}

{
    my $call = JSON::RPC::Common::Procedure::Call->new(
        method => "/app/foo/baz",
        params => [],
    );
    
    my $res = $d->handler($call, baz => 'This is a BAZ');
    isa_ok($res, 'JSON::RPC::Common::Procedure::Return');

    ok($res->has_result, '... we have a result, not an error');
    ok(!$res->has_error, '... we have a result, not an error');

    is($res->result, 'This is a BAZ', '... got the result we expected');
}


