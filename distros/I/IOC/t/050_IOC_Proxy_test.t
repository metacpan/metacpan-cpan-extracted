#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 67;

BEGIN {
    use_ok('IOC::Proxy');
}

# NOTE:
# this tests that we are successful 
# even with the case of multiple 
# (diamond) inheritance.
#
#          Base
#          /  \
#  Base::One  Base::Two
#         \   / 
#       Base::Three
#           |
#           V
#   Base::Three::_::Proxy

{ 
    package Base;
    
    sub new  { bless {}, ref($_[0]) || $_[0] }
    sub base { return (caller(1))[3] }
    
    package Base::One;
    our @ISA = 'Base';
    
    sub test { return "... I am Base::One::test" }
    sub base_one { return "... I am Base::One::base_one" }
    sub base_one_test { return "... I am Base::One::base_one_test" }
    
    package Base::Two;
    our @ISA = 'Base';

    sub test { return "... I am Base::Two::test" }
    sub base_two { return "... I am Base::Two::base_two" }
    sub base_two_test { return "... I am Base::Two::base_two_test" }
    
    package Base::Three;
    our @ISA = ('Base::One', 'Base::Two');
    
    sub new  { bless {}, ref($_[0]) || $_[0] }
    sub base_three_test { (shift)->base() }
}

my $obj_to_proxy = Base::Three->new();
isa_ok($obj_to_proxy, 'Base::Three');

my (@method_call, @wrap);

my $proxy_server = IOC::Proxy->new({ 
                            on_method_call => sub {
                                push @method_call, \@_;
                                },
                            on_wrap => sub {
                                push @wrap, \@_;                                
                                }
                            });
isa_ok($proxy_server, 'IOC::Proxy');

my $proxy = $proxy_server->wrap($obj_to_proxy);
isa_ok($proxy, 'Base::Three::_::Proxy');
isa_ok($proxy, 'Base::Three');
isa_ok($proxy, 'Base::Two');
isa_ok($proxy, 'Base::One');
isa_ok($proxy, 'Base');

is(overload::StrVal($obj_to_proxy), overload::StrVal($proxy), '... these are the same instances deep down');
isa_ok($obj_to_proxy, 'Base::Three::_::Proxy');

is_deeply(\@wrap, [ [ $proxy_server, $obj_to_proxy, 'Base::Three::_::Proxy' ] ], '... got what we expected');

ok(UNIVERSAL::isa($proxy, 'Base::Three'), '... our proxy is a Base::Three');
ok(UNIVERSAL::isa($proxy, 'Base::Two'), '... our proxy is a Base::Two');
ok(UNIVERSAL::isa($proxy, 'Base::One'), '... our proxy is a Base::One');
ok(UNIVERSAL::isa($proxy, 'Base'), '... our proxy is a Base');

can_ok($proxy, 'new');
can_ok($proxy, 'base_two_test');
can_ok($proxy, 'base_two');
can_ok($proxy, 'test');
can_ok($proxy, 'base_one_test');
can_ok($proxy, 'base_one');
can_ok($proxy, 'base');

ok(UNIVERSAL::can($proxy, 'new'), '... our proxy responded correctly to "can"');
ok(UNIVERSAL::can($proxy, 'base_two_test'), '... our proxy responded correctly to "can"');
ok(UNIVERSAL::can($proxy, 'base_two'), '... our proxy responded correctly to "can"');
ok(UNIVERSAL::can($proxy, 'test'), '... our proxy responded correctly to "can"');
ok(UNIVERSAL::can($proxy, 'base_one_test'), '... our proxy responded correctly to "can"');
ok(UNIVERSAL::can($proxy, 'base_one'), '... our proxy responded correctly to "can"');
ok(UNIVERSAL::can($proxy, 'base'), '... our proxy responded correctly to "can"');

is_deeply(\@method_call, [], '... nothing, as we expected');

is($proxy->base_two_test(1, 2, 3), '... I am Base::Two::base_two_test', '... got what we expected');
is($proxy->base_two(4, 5, 6), '... I am Base::Two::base_two', '... got what we expected');
is($proxy->test(7, 8, 9), '... I am Base::One::test', '... got what we expected');
is($proxy->base_one_test(10, 11, 12), '... I am Base::One::base_one_test', '... got what we expected');
is($proxy->base_one(13, 14, 15), '... I am Base::One::base_one', '... got what we expected');
is($proxy->base_three_test(16, 17, 18), 'Base::Three::base_three_test', '... got the caller info we expected');

is_deeply(\@method_call, [
         [ $proxy_server, 'base_two_test', 'Base::Two::base_two_test', [ $proxy, 1, 2, 3 ] ],
         [ $proxy_server, 'base_two', 'Base::Two::base_two', [ $proxy, 4, 5, 6 ] ],
         [ $proxy_server, 'test', 'Base::One::test', [ $proxy, 7, 8, 9 ] ],
         [ $proxy_server, 'base_one_test', 'Base::One::base_one_test', [ $proxy, 10, 11, 12 ] ],
         [ $proxy_server, 'base_one', 'Base::One::base_one', [ $proxy, 13, 14, 15 ] ],
         [ $proxy_server, 'base_three_test', 'Base::Three::base_three_test', [ $proxy, 16, 17, 18 ] ],
         # and dont forget the internal call as well
         [ $proxy_server, 'base', 'Base::base', [ $proxy ] ]                
         ], '... got all that we expected');

# and now create a new proxy object 
# from our original one and make sure
# it too can do all that the original 
# can do.

my $proxy2 = $proxy->new();

isnt($proxy, $proxy2, '... they are not the same instance');

isa_ok($proxy2, 'Base::Three::_::Proxy');
isa_ok($proxy2, 'Base::Three');
isa_ok($proxy2, 'Base::Two');
isa_ok($proxy2, 'Base::One');
isa_ok($proxy2, 'Base');

ok(UNIVERSAL::isa($proxy2, 'Base::Three'), '... our proxy is a Base::Three');
ok(UNIVERSAL::isa($proxy2, 'Base::Two'), '... our proxy is a Base::Two');
ok(UNIVERSAL::isa($proxy2, 'Base::One'), '... our proxy is a Base::One');
ok(UNIVERSAL::isa($proxy2, 'Base'), '... our proxy is a Base');

can_ok($proxy2, 'new');
can_ok($proxy2, 'base_two_test');
can_ok($proxy2, 'base_two');
can_ok($proxy2, 'test');
can_ok($proxy2, 'base_one_test');
can_ok($proxy2, 'base_one');
can_ok($proxy2, 'base');

is($proxy2->base_two_test(), '... I am Base::Two::base_two_test', '... got what we expected');
is($proxy2->base_two(), '... I am Base::Two::base_two', '... got what we expected');
is($proxy2->test(), '... I am Base::One::test', '... got what we expected');
is($proxy2->base_one_test(), '... I am Base::One::base_one_test', '... got what we expected');
is($proxy2->base_one(), '... I am Base::One::base_one', '... got what we expected');
is($proxy2->base_three_test(), 'Base::Three::base_three_test', '... got the caller info we expected');

ok(UNIVERSAL::can($proxy2, 'new'), '... our proxy responded correctly to "can"');
ok(UNIVERSAL::can($proxy2, 'base_two_test'), '... our proxy responded correctly to "can"');
ok(UNIVERSAL::can($proxy2, 'base_two'), '... our proxy responded correctly to "can"');
ok(UNIVERSAL::can($proxy2, 'test'), '... our proxy responded correctly to "can"');
ok(UNIVERSAL::can($proxy2, 'base_one_test'), '... our proxy responded correctly to "can"');
ok(UNIVERSAL::can($proxy2, 'base_one'), '... our proxy responded correctly to "can"');
ok(UNIVERSAL::can($proxy2, 'base'), '... our proxy responded correctly to "can"');
