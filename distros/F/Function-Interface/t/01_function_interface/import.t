use Test2::V0;

use Function::Interface;
use Types::Standard -types;

sub positional() { !!0 }
sub named()      { !!1 }
sub required()   { !!0 }
sub optional()   { !!1 }

sub function_info {
    my $name = shift;
    my $info = Function::Interface::info __PACKAGE__;
    my @f = grep { $_->subname eq $name } @{$info->functions};
    return $f[0]
}

sub test {
    my ($name, $expected) = @_;

    my ($keyword, $subname, $params, $return) = @$expected;
    my $info = function_info $name;

    note "TEST $keyword $subname";

    is $info->keyword, $keyword, 'keyword';
    is $info->subname, $subname, 'subname';

    for (my $i = 0; $i < @{$info->params}; $i++) {
        my $p = $info->params->[$i];
        my ($type, $name, $named, $optional) = @{$params->[$i]};

        is $p->type_display_name, $type, "param $i type";
        is $p->name, $name, "param $i name";
        is $p->named, $named, "param $i named";
        is $p->optional, $optional, "param $i optional";
    }

    for (my $i = 0; $i < @{$info->return}; $i++) {
        my $r = $info->return->[$i];
        my $type = $return->[$i];

        is $r->type_display_name, $type, "return $i type";
    }
}

subtest 'empty params & return' => sub {
    fun foo1() :Return();
    method foo2() :Return();

    test foo1 => ['fun', 'foo1', [], []];
    test foo2 => ['method', 'foo2', [], []];
};


subtest 'params & empty return' => sub {
    fun bar1(Str $msg) :Return();
    fun bar2(Str $msg=) :Return();
    fun bar3(Str :$msg) :Return();
    fun bar4(Str :$msg=) :Return();
    fun bar5(Str $msg, Int $i) :Return();

    test bar1 => ['fun', 'bar1', [ ['Str', '$msg', positional, required] ], []];
    test bar2 => ['fun', 'bar2', [ ['Str', '$msg', positional, optional] ], []];
    test bar3 => ['fun', 'bar3', [ ['Str', '$msg', named, required] ], []];
    test bar4 => ['fun', 'bar4', [ ['Str', '$msg', named, optional] ], []];
    test bar5 => ['fun', 'bar5', [ ['Str', '$msg', positional, required], ['Int', '$i', positional, required] ], []];
};


subtest 'empty params & return' => sub {
    fun baz1() :Return(Str);
    fun baz2() :Return(Str, Int);

    test baz1 => ['fun', 'baz1', [], ['Str']];
    test baz2 => ['fun', 'baz2', [], ['Str', 'Int']];
};

subtest 'syntax error' => sub {
    my @data = (
        'fun a() :Return()'          => 'invalid interface', 'no semicolon',
        'fun a :Return();'           => 'invalid interface', 'params / no bracket',
        'fun a( :Return();'          => 'invalid interface', 'params / no right bracket',
        'fun a) :Return();'          => 'invalid interface', 'params / no left bracket',
        'fun a($i) :Return();'       => 'invalid interface params', 'params / no type',
        'fun a(Int) :Return();'      => 'invalid interface params', 'params / no var',
        'fun a(Int i) :Return();'    => 'invalid interface params', 'params / invalid var',
        'fun a($Int $i) :Return();'  => 'invalid interface params', 'params / invalid type',
        'fun a();'                   => 'invalid interface', 'no return',
        'fun a() :return();'         => 'invalid interface', 'invalid return attribute',
        'fun a() A :return();'       => 'invalid interface', 'invalid',
        'fun a() :Return($a);'       => 'invalid interface return', 'invalid return type',
        'fun a() :Return(Str, $a);'  => 'invalid interface return', 'invalid second return type',
    );

    while (my ($src, $error_message, $comment) = splice @data, 0,3) {
        eval $src;
        like $@, qr/$error_message/, $comment;
    }
};

done_testing;
