#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 30;

my $error1 = qr{^Can't locate object method "private" via package "Method::Lexical::Test"};
my $error2 = qr{^Can't locate object method "method_private_test" via package "Method::Lexical::Test"};
my ($name, $public, $private) = qw(method_private_test public private);

my $test = Method::Lexical::Test->new();

is($test->public(), 'private!', 'public method can call a private method');
is($test->$public, 'private!', 'public method can call a private method (dynamic)');

eval { $test->private() };
like($@, $error1, "can't call private method from an outside scope");
eval { $test->$private() };
like($@, $error1, "can't call private method from an outside scope (dynamic)");

package Method::Lexical::Test;

{
    use Method::Lexical 'UNIVERSAL::method_private_test' => sub { 'method_private_test!' };

    my $test = Method::Lexical::Test->new();

    ::is(Method::Lexical::Test->method_private_test(), 'method_private_test!', 'UNIVERSAL (list): private class method');
    ::is(Method::Lexical::Test->$name(), 'method_private_test!', 'UNIVERSAL (list): private class method (dynamic)');
    ::is($test->method_private_test(), 'method_private_test!', 'UNIVERSAL (list): private instance method');
    ::is($test->$name(), 'method_private_test!', 'UNIVERSAL (list): private instance method (dynamic)');

    {
        ::is(Method::Lexical::Test->method_private_test(), 'method_private_test!', 'UNIVERSAL (list): nested private class method');
        ::is(Method::Lexical::Test->$name(), 'method_private_test!', 'UNIVERSAL (list): nested private class method (dynamic)');
        ::is($test->method_private_test(), 'method_private_test!', 'UNIVERSAL (list): nested private instance method');
        ::is($test->$name(), 'method_private_test!', 'UNIVERSAL (list): nested private instance method (dynamic)');
    }
}

# confirm import works with a hashref
{
    use Method::Lexical { 'UNIVERSAL::method_private_test' => sub { 'method_private_test!' } };

    my $test = Method::Lexical::Test->new();

    ::is(Method::Lexical::Test->method_private_test(), 'method_private_test!', 'UNIVERSAL (hashref): private class method');
    ::is(Method::Lexical::Test->$name(), 'method_private_test!', 'UNIVERSAL (hashref): private class method (dynamic)');
    ::is($test->method_private_test(), 'method_private_test!', 'UNIVERSAL (hashref): private instance method');
    ::is($test->$name(), 'method_private_test!', 'UNIVERSAL (hashref): private instance method (dynamic)');

    {
        ::is(Method::Lexical::Test->method_private_test(), 'method_private_test!', 'UNIVERSAL (hashref): nested private class method');
        ::is(Method::Lexical::Test->$name(), 'method_private_test!', 'UNIVERSAL (hashref): nested private class method (dynamic)');
        ::is($test->method_private_test(), 'method_private_test!', 'UNIVERSAL (hashref): nested private instance method');
        ::is($test->$name(), 'method_private_test!', 'UNIVERSAL (hashref): nested private instance method (dynamic)');
    }
}

{
    my $test = Method::Lexical::Test->new();

    eval { Method::Lexical::Test->method_private_test() };
    ::like($@, $error2, "can't call private class method in outer scope");

    eval { Method::Lexical::Test->$name() };
    ::like($@, $error2, "can't call private class method in outer scope (dynamic)");

    eval { $test->method_private_test() };
    ::like($@, $error2, "can't call private instance method in outer scope");

    eval { $test->$name() };
    ::like($@, $error2, "can't call private instance method in outer scope (dynamic)");
}

{
    my $external;

    BEGIN { $external = sub { 'Test::More::method_private_external_test!' } }
    use Method::Lexical 'Test::More::method_private_external_test' => $external;
    my $external_name = 'method_private_external_test';

    ::is(
        Test::More->method_private_external_test(),
        'Test::More::method_private_external_test!',
        'lexically overlaid method works'
    );

    ::is(
        Test::More->$external_name(),
        'Test::More::method_private_external_test!',
        'lexically overlaid method works (dynamic)'
    );
}

{
    use Method::Lexical private => sub { 'private!' };

    sub new {
        my $class = shift;
        bless { @_ }, ref $class || $class;
    }

    sub public {
        my $self = shift;
        $self->private();
    }

    no Method::Lexical;

    eval { Method::Lexical::Test->new->private() };
    ::like($@, $error1, 'no(...) unimports lexical instance method');

    eval { Method::Lexical::Test->new->$private() };
    ::like($@, $error1, 'no(...) unimports lexical instance method (dynamic)');

    eval { Method::Lexical::Test->private() };
    ::like($@, $error1, 'no(...) unimports lexical class method');

    eval { Method::Lexical::Test->$private() };
    ::like($@, $error1, 'no(...) unimports lexical class method (dynamic)');
}
