#!/usr/bin/env perl
use strict;
use warnings;
use Error ':try';
use Test::More tests => 52;
use Error::Hierarchy::Mixin;
use Error::Hierarchy::Util qw/assert_defined assert_is_integer/;
use Error::Hierarchy::Container;
use Error::Hierarchy::Internal::Class;
use Error::Hierarchy::Internal::CustomMessage;

sub uuid_ok {
    my $E = shift;
    our $h4 ||= qr/[0-9A-F]{4}/;
    like(
        $E->uuid,
        qr/^$h4$h4-$h4-$h4-$h4-$h4$h4$h4$/,
        sprintf "%s: uuid structure",
        ref($E)
    );
}
try { throw Error::Hierarchy }
catch Error with {
    my $E = shift;
    isa_ok($E, 'Error::Hierarchy') or warn $E;
    uuid_ok($E);
    ok($E eq 'Died', "message comparison with 'eq'");
    ok($E ne 'Foo', "message comparison with 'ne'");
    is($E->message, 'Died', 'Error::Hierarchy: message() method');
    is($E->package, 'main', 'Error::Hierarchy: reported package');
    is("$E",        'Died', 'Error::Hierarchy: stringified exception');
};
try { throw Error::Hierarchy(message => 'Foobar') }
catch Error with {
    my $E = shift;
    isa_ok($E, 'Error::Hierarchy') or warn $E;
    uuid_ok($E);
    is($E->message, 'Foobar', 'Error::Hierarchy: message() method');
    is("$E",        'Foobar', 'Error::Hierarchy: stringified exception');
};
my $line;
try { $line = __LINE__; throw Error::Hierarchy::Internal }
catch Error with {
    my $E = shift;
    isa_ok($E, 'Error::Hierarchy::Internal') or warn $E;
    uuid_ok($E);
    is($E->package, __PACKAGE__,
        'Error::Hierarchy::Internal: package() method');
    is($E->filename, $0,    'Error::Hierarchy::Internal: filename() method');
    is($E->line,     $line, 'Error::Hierarchy::Internal: line() method');
    is( "$E",
        sprintf(
            'Exception: package [%s], filename [%s], line [%s]: Died',
            __PACKAGE__, $0, $line
        ),
        'Error::Hierarchy::Internal: stringified exception'
    );
};
try {
    $line = __LINE__;
    throw Error::Hierarchy::Internal(
        package  => 'Foo',
        filename => 'bar',
        line     => 42
    );
}
catch Error with {
    my $E = shift;
    isa_ok($E, 'Error::Hierarchy::Internal') or warn $E;
    uuid_ok($E);
    is($E->package,  'Foo', 'Error::Hierarchy::Internal: package() method');
    is($E->filename, 'bar', 'Error::Hierarchy::Internal: filename() method');
    is($E->line,     42,    'Error::Hierarchy::Internal: line() method');
    is( "$E",
        sprintf(
            'Exception: package [%s], filename [%s], line [%s]: Died',
            'Foo', 'bar', 42
        ),
        'Error::Hierarchy::Internal: stringified exception'
    );
};
try {
    my $obj = Abstract->new;
    $line = __LINE__;
    $obj->abstract_method();
}
catch Error with {
    my $E = shift;
    isa_ok($E, 'Error::Hierarchy::Internal::AbstractMethod') or warn $E;
    uuid_ok($E);
    is($E->package, __PACKAGE__,
        'Error::Hierarchy::Internal::AbstractMethod: package() method');
    is($E->filename, $0,
        'Error::Hierarchy::Internal::AbstractMethod: filename() method');
    is($E->line, $line+1,
        'Error::Hierarchy::Internal::AbstractMethod: line() method');
    is($E->method, 'Abstract::abstract_method',
        'Error::Hierarchy::Internal::AbstractMethod: method() method');
    is( "$E",
        sprintf(
'Exception: package [%s], filename [%s], line [%s]: called abstract method [%s]',
            __PACKAGE__, $0, $line+1, 'Abstract::abstract_method'
        ),
        'Error::Hierarchy::Internal::AbstractMethod: stringified exception'
    );
};
try {
    my $foo = Foo->new;
    $line = __LINE__;
    $foo->test_assert_defined(undef);
}
catch Error with {
    my $E = shift;
    isa_ok($E, 'Error::Hierarchy::Internal::ValueUndefined') or warn $E;
    uuid_ok($E);
    is($E->package, __PACKAGE__,
        'Error::Hierarchy::Internal::ValueUndefined: package() method');
    is($E->filename, $0,
        'Error::Hierarchy::Internal::ValueUndefined: filename() method');
    is($E->line, $line+1,
        'Error::Hierarchy::Internal::ValueUndefined: line() method');
    is( "$E",
        sprintf(
'Exception: package [%s], filename [%s], line [%s]: [%s] called with an undef value',
            __PACKAGE__, $0, $line+1, 'Foo::test_assert_defined'
        ),
        'Error::Hierarchy::Internal::ValueUndefined: stringified exception'
    );
};
try {
    my $foo = Foo->new;
    $line = __LINE__;
    $foo->test_assert_is_integer(0);
}
catch Error with {
    my $E = shift;
    isa_ok($E, 'Error::Hierarchy::Internal::CustomMessage') or warn $E;
    uuid_ok($E);
    is($E->package, __PACKAGE__,
        'Error::Hierarchy::Internal::CustomMessage: package() method');
    is($E->filename, $0,
        'Error::Hierarchy::Internal::CustomMessage: filename() method');
    is($E->line, $line+1,
        'Error::Hierarchy::Internal::CustomMessage: line() method');
    is( "$E",
        sprintf(
'Exception: package [%s], filename [%s], line [%s]: [%s] expected an integer value from 1 to 9',
            __PACKAGE__, $0, $line+1, 'Foo::test_assert_is_integer'
        ),
        'Error::Hierarchy::Internal::CustomMessage: stringified exception'
    );
};
try {
    my $container = Error::Hierarchy::Container->new;
    $container->items_push(
        Error::Hierarchy::Internal::CustomMessage->new(
            custom_message => 'Hello'
        ),
        Error::Hierarchy::Internal::Class->new(
            class_expected => 'Foo',
            class_got      => 'Bar'
        ),
    );
    throw $container;
}
catch Error::Hierarchy::Container with {
    my $E = shift;
    my $msg =
qr/Exception: package \[main\], filename \[.*?\], line \[\d+\]: Hello\n\nException: package \[main\], filename \[.*?\], line \[\d+\]: expected a \[Foo\] object, got \[Bar\]/;
    like("$E", $msg, 'Stringified container');
};
my $E = Error::Hierarchy->new;
uuid_ok($E);
is($E->is_optional, 0, 'Exception is mandatory by default');
$E->is_optional(1);
is($E->is_optional, 1, 'Exception can be set optional via accessor');
$E->is_optional(0);
is($E->is_optional, 0, 'Exception can be set mandatory via accessor');
$E = Error::Hierarchy->new(is_optional => 1);
is($E->is_optional, 1, 'Exception can be set optional via constructor');
$E = Error::Hierarchy->new(is_optional => 0);
is($E->is_optional, 0, 'Exception can be set mandatory via constructor');
$E = Error::Hierarchy::Internal->new;
is($E->is_optional, 0, 'Internal exception is mandatory by default');
$E = Error::Hierarchy::Internal->new(is_optional => 1);
is($E->is_optional, 0,
    "Internal exception can't be set optional via constructor");
$E->is_optional(1);
is($E->is_optional, 0, "Internal exception can't be set optional via accessor");

package Foo;
use Error::Hierarchy::Util ':all';
sub new { bless {}, shift }

sub test_assert_defined {
    my ($self, $val) = @_;
    assert_defined($val, 'called with an undef value');
}

sub test_assert_is_integer {
    my ($self, $val) = @_;
    assert_is_integer($val);
}

package Abstract;
sub new { bless {}, shift }
sub abstract_method { throw Error::Hierarchy::Internal::AbstractMethod }
1;
