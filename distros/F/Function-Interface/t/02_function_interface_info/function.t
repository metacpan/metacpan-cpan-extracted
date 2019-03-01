use Test2::V0;

use Function::Interface::Info::Function;

subtest 'basic' => sub {
    my $info = Function::Interface::Info::Function->new(
        subname => 'hello',
        keyword => 'fun',
        params  => [],
        return  => [],
    );

    isa_ok $info, 'Function::Interface::Info::Function';
    is $info->subname, 'hello';
    is $info->keyword, 'fun';
    is $info->params, [];
    is $info->return, [];
};

subtest 'definition' => sub {
    is d('fun','hello', [], []), 'fun hello() :Return()';
    is d('fun','hello2', [], []), 'fun hello2() :Return()';
    is d('method','hello', [], []), 'method hello() :Return()';

    is d('fun','hello', [ ['Str', '$msg'] ], []), 'fun hello(Str $msg) :Return()';
    is d('fun','hello', [ ['Str', '$msg'], ['Int', '$i'] ], []), 'fun hello(Str $msg, Int $i) :Return()';
    is d('fun','hello', [ ['Str', '$msg', 1] ], []), 'fun hello(Str $msg=) :Return()';
    is d('fun','hello', [ ['Str', '$msg', 0,1] ], []), 'fun hello(Str :$msg) :Return()';
    is d('fun','hello', [ ['Str', '$msg', 1,1] ], []), 'fun hello(Str :$msg=) :Return()';

    is d('method','hello', [], ['Str']), 'method hello() :Return(Str)';
    is d('method','hello', [], ['Str', 'Int']), 'method hello() :Return(Str, Int)';
};

subtest 'params' => sub {
    my @params = (
        #           opt named
        ['Str', '$a', 0, 0],
        ['Str', '$e', 1, 0],
        ['Str', '$h', 0, 1],
        ['Str', '$j', 1, 1],
        ['Str', '$b', 0, 0],
        ['Str', '$f', 1, 0],
        ['Str', '$i', 0, 1],
        ['Str', '$c', 0, 0],
        ['Str', '$g', 1, 0],
        ['Str', '$d', 0, 0],
    );

    my $info = make_info_function('fun', 'foo', \@params, []);

    is [map { $_->name } @{$info->positional_required}], ['$a', '$b', '$c', '$d'];
    is [map { $_->name } @{$info->positional_optional}], ['$e', '$f', '$g'];
    is [map { $_->name } @{$info->named_required}], ['$h', '$i'];
    is [map { $_->name } @{$info->named_optional}], ['$j'];
};

sub d { make_info_function(@_)->definition }

sub make_info_function {
    my ($keyword, $subname, $params, $return) = @_;

    return Function::Interface::Info::Function->new(
        subname => $subname,
        keyword => $keyword,
        params  => [ map { mock_param($_) } @{$params} ],
        return  => [ map { mock_return($_) } @{$return} ],
    );
}

sub mock_param {
    my ($type, $name, $optional, $named) = @{$_[0]};

    mock {
        type_display_name => $type,
        name              => $name,
        optional          => $optional,
        named             => $named,
    };
}

sub mock_return {
    my ($type) = @_;
    mock {
        type_display_name => $type,
    };
}

done_testing;
