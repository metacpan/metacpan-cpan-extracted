use strict;
use warnings;
use Test::More;

use Micro::Container;

my $container = Micro::Container->instance;

sub test_unregister {
    my @names = @_;

    $container->unregister(@names);
    for my $name (@names) {
        eval { $container->get($name) };
        like $@, qr/$name is not registered/;
    }
}

subtest 'register single' => sub {
    $container->register('t::Foo' => []);
    my $foo = $container->get('t::Foo');
    isa_ok $foo, 't::Foo';

    test_unregister('t::Foo');
};

subtest 'register single with args' => sub {
    $container->register('t::Foo' => [ foo => 'bar' ]);
    my $foo = $container->get('t::Foo');
    isa_ok $foo, 't::Foo';
    is $foo->{foo}, 'bar';

    test_unregister('t::Foo');
};

subtest 'register single with cb' => sub {
    $container->register('t::Foo' => sub {
        my ($c, $name) = @_;
        $c->load_class($name)->new(hoge => 'fuga');
    });
    my $foo = $container->get('t::Foo');
    isa_ok $foo, 't::Foo';
    is $foo->{hoge}, 'fuga';

    test_unregister('t::Foo');
};

subtest 'register single with cb (other name)' => sub {
    $container->register('XXX' => sub {
        my ($c, $name) = @_;
        $c->load_class('t::Foo')->new(x => 'y');
    });
    my $foo = $container->get('XXX');
    isa_ok $foo, 't::Foo';
    is $foo->{x}, 'y';

    test_unregister('XXX');
};

subtest 'register multiple' => sub {
    $container->register(
        't::Foo' => sub {
            my ($c, $name) = @_;
            $c->load_class($name)->new(xxx => 'yyy');
        },
        't::Bar' => [ fizz => 'buzz' ],
    );

    my $foo = $container->get('t::Foo');
    isa_ok $foo, 't::Foo';
    is $foo->{xxx}, 'yyy';

    my $bar = $container->get('t::Bar');
    isa_ok $bar, 't::Bar';
    is $bar->{fizz}, 'buzz';

    test_unregister('t::Foo', 't::Bar');
};

done_testing;
