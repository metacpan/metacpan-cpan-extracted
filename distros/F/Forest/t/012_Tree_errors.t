#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;

BEGIN {
    use_ok('Forest::Tree');
};

my $t = Forest::Tree->new();
isa_ok($t, 'Forest::Tree');

# test some errors

throws_ok {
    $t->add_child(undef);
} qr/Child parameter must be a Forest\:\:Tree not/, '... throws exception';

throws_ok {
    $t->add_child([]);
} qr/Child parameter must be a Forest\:\:Tree not/, '... throws exception';

throws_ok {
    $t->add_child({});
} qr/Child parameter must be a Forest\:\:Tree not/, '... throws exception';

throws_ok {
    $t->add_child(bless {} => 'Foo');
} qr/Child parameter must be a Forest\:\:Tree not/, '... throws exception';

throws_ok {
    $t->insert_child_at(undef);
} qr/Child parameter must be a Forest\:\:Tree not/, '... throws exception';

throws_ok {
    $t->insert_child_at([]);
} qr/Child parameter must be a Forest\:\:Tree not/, '... throws exception';

throws_ok {
    $t->insert_child_at({});
} qr/Child parameter must be a Forest\:\:Tree not/, '... throws exception';

throws_ok {
    $t->insert_child_at(bless {} => 'Foo');
} qr/Child parameter must be a Forest\:\:Tree not/, '... throws exception';

