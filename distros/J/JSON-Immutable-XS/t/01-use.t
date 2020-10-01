use 5.020;
use Test::More;
use Test::Deep;

BEGIN {
   use_ok('JSON::Immutable::XS');
};

my $dict_obj = JSON::Immutable::XS->new('t/var/dict/test.json');

subtest init => sub {
    isa_ok $dict_obj, 'JSON::Immutable::XS';
    ok defined $dict_obj->get('testhash', 'obj');

    ok not defined $dict_obj->get('testhash', 'bad_key');
    ok defined $dict_obj->get('testhash', 'arr');
    ok defined $dict_obj->get('testarr' , 1);
    ok defined $dict_obj->get('testarr' , 2, 'asd');
    ok not defined $dict_obj->get('testarr' , 2, 'asd', 'qqq');
};
$dict_obj->dump();

subtest export => sub {
    is $dict_obj->get('testarr' , 2, 'asd')->export(), 42;

    my $str_child = $dict_obj->get('ident');
    is $str_child->export(), "test";

    my $int_child = $dict_obj->get('testint');
    is $int_child->export(), 42;

    my $float_child = $dict_obj->get('testfloat');
    ok $float_child->export() < 42.43;
    ok $float_child->export() > 42.41;

    my $bool_child = $dict_obj->get('testbool-1');
    is $bool_child->export(), 0;
    $bool_child = $dict_obj->get('testbool-2');
    is $bool_child->export(), 1;

    my $hash = $dict_obj->get('testhash');
    cmp_deeply $hash->export(),
        {
            arr  => [1, 0],
            obj  => { qqq => 111, "undef" => undef },
            test => 1
        };

    my $array = $dict_obj->get('testarr');
    cmp_deeply $array->export(),
        [
            '1',
            '2',
            {
                'asd' => '42',
                'zxc' => '13'
            },
            [1, 2, 3]
        ];
};

subtest keys => sub {
    my $tmp = $dict_obj->get('testarr');
    cmp_deeply $dict_obj->get('testarr')->keys(), [];
    cmp_deeply $dict_obj->get('testhash')->keys(), ['arr', 'obj', 'test'];
};

subtest get_value => sub {
    ok $dict_obj->get_value('testfloat') < 42.43;
    ok $dict_obj->get_value('testfloat') > 42.41;
    cmp_deeply $dict_obj->get_value('testhash'),
        {
            arr  => [1, 0],
            obj  => { qqq => 111, "undef" => undef },
            test => 1
        };
    my $child = $dict_obj->get('testhash');
    is $child->get_value('test'), 1;

    my $next = $child->get('obj');
    is $next->get_value('qqq'), 111;
    is $next->get_value('qqq', 'aaa'), undef;
    is $next->get_value('ddfdfdf'), undef;
};

subtest exists => sub {
    is $dict_obj->exists('testarr'), 1;
    is $dict_obj->exists('testarr', 1), 1;
    is $dict_obj->exists('testarr', 99), 0;
    is $dict_obj->exists('testhash', 'obj', 'qqq'), 1;
    is $dict_obj->exists('no'), 0;
};

subtest size => sub {
    is $dict_obj->get('testarr')->size(), 4;
    is $dict_obj->size('testarr'), 4;
    is $dict_obj->get('testhash')->size(), 3;
    is $dict_obj->size('testhash'), 3;
    is $dict_obj->size('testhash', 'arr'), 2;
    is $dict_obj->size('testint'), undef;
};


done_testing();
