#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Legba');

# Test empty string vs undef
subtest 'empty string vs undef' => sub {
    package EdgePkg1;
    use Legba qw/empty_slot/;
    
    empty_slot('');
    Test::More::is(empty_slot(), '', 'empty string stored');
    Test::More::ok(defined empty_slot(), 'empty string is defined');
    
    empty_slot(undef);
    Test::More::ok(!defined empty_slot(), 'undef is not defined');
};

# Test zero vs false
subtest 'zero and false values' => sub {
    package EdgePkg2;
    use Legba qw/zero_slot false_slot/;
    
    zero_slot(0);
    Test::More::is(zero_slot(), 0, 'zero stored');
    Test::More::ok(defined zero_slot(), 'zero is defined');
    
    false_slot('0');
    Test::More::is(false_slot(), '0', 'string zero stored');
};

# Test very long strings
subtest 'long strings' => sub {
    package EdgePkg3;
    use Legba qw/long_slot/;
    
    my $long = 'x' x 100000;
    long_slot($long);
    Test::More::is(length(long_slot()), 100000, 'long string length preserved');
    Test::More::is(long_slot(), $long, 'long string content preserved');
};

# Test unicode
subtest 'unicode' => sub {
    package EdgePkg4;
    use Legba qw/unicode_slot/;
    
    my $unicode = "Hello \x{263A} \x{2665} \x{1F600}";
    unicode_slot($unicode);
    Test::More::is(unicode_slot(), $unicode, 'unicode preserved');
};

# Test binary data
subtest 'binary data' => sub {
    package EdgePkg5;
    use Legba qw/binary_slot/;
    
    my $binary = join('', map { chr($_) } 0..255);
    binary_slot($binary);
    Test::More::is(length(binary_slot()), 256, 'binary length preserved');
    Test::More::is(binary_slot(), $binary, 'binary content preserved');
};

# Test numeric precision
subtest 'numeric precision' => sub {
    package EdgePkg6;
    use Legba qw/float_slot int_slot/;
    
    float_slot(3.141592653589793);
    Test::More::ok(abs(float_slot() - 3.141592653589793) < 1e-15, 'float precision');
    
    int_slot(9007199254740992);  # 2^53
    Test::More::is(int_slot(), 9007199254740992, 'large integer');
    
    int_slot(-9007199254740992);
    Test::More::is(int_slot(), -9007199254740992, 'large negative integer');
};

# Test rapid overwrite
subtest 'rapid overwrite' => sub {
    package EdgePkg7;
    use Legba qw/overwrite_slot/;
    
    for my $i (1..1000) {
        overwrite_slot($i);
    }
    Test::More::is(overwrite_slot(), 1000, 'last value survives rapid overwrite');
};

# Test slot name with underscores and numbers
subtest 'slot naming' => sub {
    package EdgePkg8;
    use Legba qw/slot_1 _private slot_with_long_name_123/;
    
    Test::More::can_ok('EdgePkg8', 'slot_1');
    Test::More::can_ok('EdgePkg8', '_private');
    Test::More::can_ok('EdgePkg8', 'slot_with_long_name_123');
    
    slot_1(1);
    _private(2);
    slot_with_long_name_123(3);
    
    Test::More::is(slot_1(), 1, 'numbered slot works');
    Test::More::is(_private(), 2, 'underscore prefix works');
    Test::More::is(slot_with_long_name_123(), 3, 'long name works');
};

done_testing();
