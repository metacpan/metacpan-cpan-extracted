#!/usr/bin/env perl

use Test::Most;
use Method::Delegation;

{

    package First;
    use Method::Delegation;

    sub new {
        my $class = shift;
        return bless {
            second => Second->new,
            third  => Third->new,
        } => $class;
    }

    sub second { shift->{second} }
    sub third  { shift->{third} }
    sub fourth { }
    sub fifth  { }

    delegate(
        methods => 'name',
        to      => 'second',
    );
    delegate(
        methods => { reverse => 'frobnicate' },
        to      => 'third',
        args    => 1,
    );
    delegate(
        methods  => { shortcut => 'returns_something' },
        maybe_to => 'third',
    );
    delegate(
        methods  => { maybe_something => 'returns_something' },
        maybe_to => 'third',
    );
    delegate(
        methods => [qw/this that/],
        to      => 'fourth',
        if_true => 'fourth',
    );
    delegate(
        methods  => 'faily_fail',
        maybe_to => 'fourth',
    );
    delegate(
        methods     => [qw/oui non/],
        maybe_to    => 'fifth',
        else_return => 'fail!',
    );

    sub foo { return 'foo' }
}
ok my $object = First->new,
  'We should be able to create an object which delegates to another object';
is $object->name, 'Second', '... and have the delegated methods work';
is $object->reverse('foobar'), 'raboof',
  '... and we can send arguments, if needed';
ok !$object->this, '... and methods we cannot delegate return false';
is $object->non, 'fail!',
  '... and else_return can specify a return value if the method returns false';
is $object->shortcut, 'something',
  'Our "maybe_to" shortcut should work as intended';
ok !$object->faily_fail, '... even if the delegated object does not exist';
is $object->maybe_something, 'something', 'Using "maybe_to" works as expected';

# exceptions

# main:: is not a class and we have nothing to delegate to,
# but that doesn't stop us from testing exceptions
my %delegate;
throws_ok { delegate(%delegate) }
qr/\QYou must supply a 'to' argument to delegate()/,
  'Not specifing a method to delegate to should fail';

$delegate{to} = 'frobnitz';
throws_ok { delegate(%delegate) }
qr/\QYou must supply a 'methods' argument to delegate()/,
  '... not specifing methods to delegate should fail';

$delegate{methods} = qr/name/;
throws_ok { delegate(%delegate) }
qr/\QI don't know how to delegate to 'frobnitz' from/,
  '... and specifying something "weird" for methods should fail';

$delegate{methods} = '111egal method name';
throws_ok { delegate(%delegate) }
qr/\QIllegal method name: '111egal method name'/,
  '... and specifying illegal method names should fail';

$delegate{maybe_to} = 'whatever';
throws_ok { delegate(%delegate) }
qr/\QYou supplied both 'maybe_to' and 'to'. I don't know which to use./,
  'Supplying both "to" and "maybe_to" should fail';

done_testing;

{

    package Second;

    sub new {
        my $class = shift;
        return bless {} => $class;
    }

    sub name { return __PACKAGE__ }
}

{

    package Third;
    sub new { bless {} => shift }

    sub frobnicate {
        my ( $self, $string ) = @_;
        return scalar reverse $string;
    }

    sub returns_something { 'something' }
}
