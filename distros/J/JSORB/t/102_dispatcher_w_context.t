#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;

use JSON::RPC::Common::Procedure::Call;

BEGIN {
    use_ok('JSORB');
    use_ok('JSORB::Dispatcher::Path');
}

{
    package My::Mock::Context;
    use Moose;
    
    has 'who' => (
        is      => 'ro',
        isa     => 'Str',   
        default => sub { 'World' },
    );
}

my $ns = JSORB::Namespace->new(
    name     => 'App',
    elements => [
        JSORB::Interface->new(
            name       => 'Test',            
            procedures => [
                JSORB::Procedure->new(
                    name  => 'greeting',
                    body  => sub {
                        my ($c) = @_;
                        return 'Hello ' . $c->who;
                    },
                    spec  => [ 'My::Mock::Context' => 'Str' ],
                ),
            ]
        )            
    ]
);
isa_ok($ns, 'JSORB::Namespace');

my $d = JSORB::Dispatcher::Path->new_with_traits(
    traits        => [ 'JSORB::Dispatcher::Traits::WithContext' ],
    namespace     => $ns,
    context_class => 'My::Mock::Context',
);
isa_ok($d, 'JSORB::Dispatcher::Path');

is($d->namespace, $ns, '... got the same namespace');

{
    my $call = JSON::RPC::Common::Procedure::Call->new(
        method => "/app/test/greeting",
        params => [],
    );
    
    my $res = $d->handler($call, My::Mock::Context->new);
    isa_ok($res, 'JSON::RPC::Common::Procedure::Return');

    ok($res->has_result, '... we have a result, not an error');
    ok(!$res->has_error, '... we have a result, not an error');

    is($res->result, 'Hello World', '... got the result we expected');
}

{
    my $call = JSON::RPC::Common::Procedure::Call->new(
        method => "/app/test/greeting",
        params => [],
    );
    
    my $res = $d->handler($call, My::Mock::Context->new(who => 'Everyone'));
    isa_ok($res, 'JSON::RPC::Common::Procedure::Return');

    ok($res->has_result, '... we have a result, not an error');
    ok(!$res->has_error, '... we have a result, not an error');

    is($res->result, 'Hello Everyone', '... got the result we expected');
}



