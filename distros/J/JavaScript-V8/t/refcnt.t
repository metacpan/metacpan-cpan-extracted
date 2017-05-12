#!/usr/bin/perl
use Test::More;
use JavaScript::V8;
use Scalar::Util 'weaken';
use utf8;
use strict;
use warnings;



my $outer;
{
    my $foo_called = 0;
    my $foo = sub {$foo_called++};
    $outer = \$foo;
    weaken($outer);
    my $context = JavaScript::V8::Context->new();
    $context->bind_function(foo => $foo);
    $context->eval('foo()');
    is $foo_called,1,"foo got called";
}
is $outer,undef,"the sub should have disappeared";


done_testing;

