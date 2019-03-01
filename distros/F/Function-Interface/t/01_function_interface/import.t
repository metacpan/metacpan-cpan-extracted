use Test2::V0;

use Function::Interface;

use B::Deparse;
use Types::Standard -types;

sub positional() { 0 }
sub named()      { 1 }
sub required()   { 0 }
sub optional()   { 1 }

my @data = (
    'fun foo() :Return();'                 => ['fun', 'foo', [], []],
    'fun bar() :Return();'                 => ['fun', 'bar', [], []],
    'method foo() :Return();'              => ['method', 'foo', [], []],
    'fun foo(Str $msg) :Return();'         => ['fun', 'foo', [ ['Str', '$msg', positional, required] ], []],
    'fun foo(Str $msg=) :Return();'        => ['fun', 'foo', [ ['Str', '$msg', positional, optional] ], []],
    'fun foo(Str :$msg) :Return();'        => ['fun', 'foo', [ ['Str', '$msg', named, required] ], []],
    'fun foo(Str :$msg=) :Return();'       => ['fun', 'foo', [ ['Str', '$msg', named, optional] ], []],
    'fun foo(Str $msg, Int $i) :Return();' => ['fun', 'foo', [ ['Str', '$msg', positional, required], ['Int', '$i', positional, required] ], []],
    'fun foo() :Return(Str);'              => ['fun', 'foo', [], ['Str']],
    'fun foo() :Return(Str, Int);'         => ['fun', 'foo', [], ['Str', 'Int']],
);

my $DEPARSE = B::Deparse->new();
sub test {
    my ($text, $expected) = @_;

    local $@;
    my $code = eval "sub { $text }";
    if ($@) {
        note "Failed eval: $@";
        fail;
    }

    my $got = $DEPARSE->coderef2text($code);

    my $params = join ', ', map { sprintf(q!\{'type', %s, 'name', '%s', 'named', %s, 'optional', %s\}!, map { quotemeta } @{$_}) } @{$expected->[2]};
    my $return = join ', ', @{$expected->[3]};
    my $e = sprintf(q!Function::Interface::_register_info\(\{'package', 'main', 'keyword', '%s', 'subname', '%s', 'params', \[%s\], 'return', \[%s\]\}\)!, $expected->[0], $expected->[1], $params, $return);

    like $got, qr/$e/;
}

while (my @d = splice @data, 0, 2) {
    test(@d);
}

done_testing;
