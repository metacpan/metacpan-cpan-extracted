#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
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

    sub baz {
        my ($self, $c) = @_;
        return join " => " => $self->bar, $c->who
    }
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
            name       => 'Foo',
            procedures => [
                JSORB::Method->new(
                    name  => 'baz',
                    spec  => [ 'My::Mock::Context' => 'Str' ],
                ),
            ]
        )
    ]
);
isa_ok($ns, 'JSORB::Namespace');

my $d = JSORB::Dispatcher::Path->new_with_traits(
    traits    => [
        'JSORB::Dispatcher::Traits::WithContext',
        'JSORB::Dispatcher::Traits::WithInvocant',
    ],
    namespace     => $ns,
    context_class => 'My::Mock::Context',
);
isa_ok($d, 'JSORB::Dispatcher::Path');


{
    my $call = JSON::RPC::Common::Procedure::Call->new(
        method => "/app/foo/baz",
        params => [],
    );

    my $res = $d->handler($call, App::Foo->new, My::Mock::Context->new);
    isa_ok($res, 'JSON::RPC::Common::Procedure::Return');

    ok($res->has_result, '... we have a result, not an error');
    ok(!$res->has_error, '... we have a result, not an error');

    is($res->result, 'BAR => World', '... got the result we expected');
}



