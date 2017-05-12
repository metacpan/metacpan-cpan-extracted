use strict;
use warnings;
use Test::More;

use t::MyCon;

subtest 'get registered object' => sub {
    my $bar = t::MyCon->get('t::Bar');
    isa_ok $bar, 't::Bar';
};

subtest 'get from parent class' => sub {
    eval { t::MyCon->get('t::Foo') };
    like $@, qr/t::Foo is not registered/;
    Micro::Container->register('t::Foo' => []);
    my $foo = t::MyCon->get('t::Foo');
    isa_ok $foo, 't::Foo';
};

done_testing;
