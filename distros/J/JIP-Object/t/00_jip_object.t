#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use English qw(-no_match_vars);

plan tests => 10;

subtest 'Require some module' => sub {
    plan tests => 4;

    use_ok 'JIP::Object', '0.03';

    require_ok 'JIP::Object';
    is $JIP::Object::VERSION, '0.03';

    diag(
        sprintf 'Testing JIP::Object %s, Perl %s, %s',
            $JIP::Object::VERSION,
            $PERL_VERSION,
            $EXECUTABLE_NAME,
    );

    can_ok 'JIP::Object', qw(new has method proto set_proto own_method);
};

subtest 'new()' => sub {
    plan tests => 5;

    eval { JIP::Object->new->new } or do {
        like $EVAL_ERROR, qr{^Class \s already \s blessed}x;
    };
    eval { JIP::Object->new(proto => 'not blessed val') } or do {
        like $EVAL_ERROR, qr{^Bad \s argument \s "proto"}x;
    };

    my $obj = JIP::Object->new;

    isa_ok $obj, qw(JIP::Object);
    is $obj->proto, undef;

    isa_ok $obj->set_proto(JIP::Object->new)->proto, 'JIP::Object';
};

subtest 'has()' => sub {
    plan tests => 17;

    eval { JIP::Object->has } or do {
        like $EVAL_ERROR, qr{^Can't \s call \s "has" \s as \s a \s class \s method}x;
    };

    my $obj = JIP::Object->new;

    eval { $obj->has } or do {
        like $EVAL_ERROR, qr{^Attribute \s not \s defined}x;
    };
    eval { $obj->has(q{}) } or do {
        like $EVAL_ERROR, qr{^Attribute \s not \s defined}x;
    };

    eval { $obj->has(42) } or do {
        like $EVAL_ERROR, qr{^Attribute \s "42" \s invalid}x;
    };

    is $obj->has(attr_1 => (get => q{-}, set => q{-}))->_set_attr_1(1)->_attr_1, 1;
    is $obj->has(attr_2 => (get => q{+}, set => q{-}))->_set_attr_2(2)->attr_2,  2;
    is $obj->has(attr_3 => (get => q{-}, set => q{+}))->set_attr_3(3)->_attr_3,  3;
    is $obj->has(attr_4 => (get => q{+}, set => q{+}))->set_attr_4(4)->attr_4,   4;

    is $obj->has(attr_5 => (get => q{getter}, set => q{setter}))->setter(5)->getter, 5;

    is $obj->has(attr_6 => (
        get     => q{+},
        set     => q{+},
        default => q{default_value},
    ))->set_attr_6(42)->attr_6, '42';
    is $obj->set_attr_6(undef)->attr_6, undef;
    is $obj->set_attr_6->attr_6, q{default_value};

    is $obj->has(attr_7 => (
        get     => q{+},
        set     => q{+},
        default => sub { shift->attr_6 },
    ))->set_attr_7(42)->attr_7, '42';
    is $obj->set_attr_7(undef)->attr_7, undef;
    is $obj->set_attr_7->attr_7, q{default_value};

    $obj->has([qw(attr_8 attr_9)] => (
        get => q{+},
        set => q{+},
    ));
    is $obj->set_attr_8(8)->attr_8, 8;
    is $obj->set_attr_9(9)->attr_9, 9;
};

subtest 'method()' => sub {
    plan tests => 7;

    eval { JIP::Object->method } or do {
        like $EVAL_ERROR, qr{^Can't \s call \s "method" \s as \s a \s class \s method}x;
    };

    my $obj = JIP::Object->new;

    eval { $obj->method(undef) } or do {
        like $EVAL_ERROR, qr{^First \s argument \s must \s be \s a \s non \s empty \s string}x;
    };
    eval { $obj->method(q{}) } or do {
        like $EVAL_ERROR, qr{^First \s argument \s must \s be \s a \s non \s empty \s string}x;
    };
    eval { $obj->method(42) } or do {
        like $EVAL_ERROR, qr{^First \s argument \s "42" \s invalid}x;
    };
    eval { $obj->method(q{foo}, undef) } or do {
        like $EVAL_ERROR, qr{^Second \s argument \s must \s be \s a \s code \s ref}x;
    };

    is ref($obj->method('foo', sub {
        pass 'foo() method is invoked';
    })), 'JIP::Object';

    $obj->foo;
};

subtest 'own_method()' => sub {
    plan tests => 2;

    my $obj = JIP::Object->new;

    is $obj->own_method('x'), undef;

    $obj->method('x', sub {
        return 'from x'
    });

    is $obj->own_method('x')->(), 'from x';
};

subtest 'AUTOLOAD()' => sub {
    plan tests => 6;

    eval { JIP::Object->AUTOLOAD } or do {
        like $EVAL_ERROR, qr{^Can't \s call \s "AUTOLOAD" \s as \s a \s class \s method}x;
    };

    my $obj = JIP::Object->new->has('foo', get => '+', set => '+')->set_foo(42);

    my $bar_result = $obj->method('bar', sub {
        my ($self, $param) = @ARG;

        is ref($self), 'JIP::Object';
        is $param, 'Hello';
        is $self->foo, 42;

        return 'tratata';
    })->bar('Hello');

    is $bar_result, 'tratata';

    eval { $obj->wtf } or do {
        like $EVAL_ERROR, qr{
            ^
            Can't \s locate \s object \s method \s "wtf"
            \s in \s this \s instance
        }x;
    };
};

subtest 'The Universal class' => sub {
    plan tests => 10;

    # Class methods
    is(JIP::Object->VERSION, '0.03');

    ok(JIP::Object->isa('JIP::Object'));

    ok(JIP::Object->DOES('JIP::Object'));

    is ref JIP::Object->can('new'), 'CODE';

    # Object methods
    my $obj = JIP::Object->new;

    is $obj->VERSION, '0.03';

    ok $obj->isa('JIP::Object');
    ok not $obj->isa('JIP::ClassField');

    is $obj->DOES('JIP::Object'),     $obj->isa('JIP::Object');
    is $obj->DOES('JIP::ClassField'), $obj->isa('JIP::ClassField');

    is ref $obj->can('new'), 'CODE';
};

subtest 'proto' => sub {
    plan tests => 10;

    my $proto = JIP::Object->new;
    my $obj   = JIP::Object->new(proto => $proto);

    # x() not in $proto, $obj
    is ref $proto->own_method('x'), q{};
    is ref $obj->own_method('x'),   q{};

    $proto->method('x', sub {
        return 'from proto::x';
    });

    # x() only in $proto
    is ref $proto->own_method('x'), 'CODE';
    is ref $obj->own_method('x'),   q{};

    # but, x() in prototype chain
    is $proto->x, 'from proto::x';
    is $obj->x,   'from proto::x';

    $obj->method('x', sub {
        return 'from obj::x';
    });

    is ref $proto->own_method('x'), 'CODE';
    is ref $obj->own_method('x'),   'CODE';

    is $proto->x, 'from proto::x';
    is $obj->x,   'from obj::x';
};

subtest '_define_name_of_getter()' => sub {
    plan tests => 4;

    my $run = sub {
        my %param = @ARG;
        JIP::Object::_define_name_of_getter('foo', \%param);
    };

    is $run->(),           'foo';
    is $run->(get => '+'), 'foo';

    is $run->(get => '-'), '_foo';

    is $run->(get => 'foo_getter'), 'foo_getter';
};

subtest '_define_name_of_setter()' => sub {
    plan tests => 4;

    my $run = sub {
        my %param = @ARG;
        JIP::Object::_define_name_of_setter('foo', \%param);
    };

    is $run->(),           'set_foo';
    is $run->(set => '+'), 'set_foo';

    is $run->(set => '-'), '_set_foo';

    is $run->(set => 'foo_setter'), 'foo_setter';
};

