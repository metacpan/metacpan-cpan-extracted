use Test2::V0;

use Function::Parameters;
use Types::Standard -types;

use Function::Interface::Impl;
use Function::Interface::Info::Function;
use Function::Interface::Info::Function::Param;

sub positional() { !!0 }
sub named()      { !!1 }
sub required()   { !!0 }
sub optional()   { !!1 }

subtest 'basic' => sub {

    fun foo(Str $msg) { }
    test(foo => ['fun', 'foo', [ [Str, '$msg', positional, required] ] ]);

    fun foo2(Str :$msg) { }
    test(foo2 => ['fun', 'foo2', [ [Str, '$msg', named, required] ] ]);

    fun foo3(Str $msg=) { }
    test(foo3 => ['fun', 'foo3', [ [Str, '$msg', positional, optional] ] ]);

    fun foo4(Str :$msg=) { }
    test(foo4 => ['fun', 'foo4', [ [Str, '$msg', named, optional] ] ]);

    fun foo5(Str $msg, Int $i) { }
    test(foo5 => ['fun', 'foo5', [ [Str, '$msg', positional, required], [Int, '$i', positional, required] ] ]);

    fun foo6() { }
    test(foo6 => ['fun', 'foo6', [ ] ]);

    method foo7() { }
    test(foo7 => ['method', 'foo7', [ ] ]);
};

subtest 'ng' => sub {

    fun bar() {}
    my $bar = info(\&bar);
    ok Function::Interface::Impl::check_params($bar, iinfo('fun', 'bar', []));
    ok not Function::Interface::Impl::check_params($bar, iinfo('method', 'bar', []));
    ok not Function::Interface::Impl::check_params($bar, iinfo('fun', 'bar', [ [Int, '$a', positional, required] ]));

    fun bar2(Str $msg) {}
    my $bar2 = info(\&bar2);
    ok Function::Interface::Impl::check_params($bar2, iinfo('fun', 'bar2', [ [Str, '$msg', positional, required] ]));
    ok not Function::Interface::Impl::check_params($bar2, iinfo('fun', 'bar2', []));
    ok not Function::Interface::Impl::check_params($bar2, iinfo('method', 'bar2', []));
    ok not Function::Interface::Impl::check_params($bar2, iinfo('fun', 'bar2', [ [Int, '$msg', positional, required] ]));
    ok not Function::Interface::Impl::check_params($bar2, iinfo('fun', 'bar2', [ [Str, '$smg', positional, required] ]));
    ok not Function::Interface::Impl::check_params($bar2, iinfo('fun', 'bar2', [ [Str, '$msg', named, required] ]));
    ok not Function::Interface::Impl::check_params($bar2, iinfo('fun', 'bar2', [ [Str, '$msg', named, optional] ]));
    ok not Function::Interface::Impl::check_params($bar2, iinfo('fun', 'bar2', [ [Str, '$msg', positional, optional] ]));

    # TODO: slurpy
    # fun bar3(Str $key, @values) {}
    # my $bar3 = info(\&bar3);
    # ok Function::Interface::Impl::check_params($bar3, iinfo('fun', 'bar3', [ [Str, '$key', positional, required] ]));
};

sub test {
    my ($name, $expected) = @_;

    my $info = info(\&$name);
    my $iinfo = iinfo(@$expected);

    ok Function::Interface::Impl::check_params($info, $iinfo);
}

sub info {
    my $code = shift;
    Function::Parameters::info $code;
}

sub iinfo {
    my ($keyword, $subname, $params) = @_;
    Function::Interface::Info::Function->new(
        subname => $subname,
        keyword => $keyword,
        params  => [map { iparam(@$_) } @$params],
    );
}

sub iparam {
    my ($type, $name, $named, $optional) = @_;
    Function::Interface::Info::Function::Param->new(
        type     => $type,
        name     => $name,
        named    => $named,
        optional => $optional,
    );
}

done_testing;
