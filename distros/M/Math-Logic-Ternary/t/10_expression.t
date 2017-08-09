# Copyright (c) 2012-2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Tests for Math::Logic::Ternary::Expression

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/10_expression.t'

#########################

use strict;
use warnings;
use Test;

BEGIN { plan tests => 63; }

use Math::Logic::Ternary::Expression qw(:all);

#########################

sub as_string {
    my ($val) = @_;
    return 'undef' if !defined $val;
    return "false('$val')" if !$val;
    return "true('$val')" if !ref $val;
    return "true(" . ref($val) . " ref)";
}

sub wrap {
    my ($val) = @_;
    my $called = 0;
    return sub { die if $called++; $val };
}

sub check {
    my ($subj, $val, $antival) = @_;
    if (!eval { $subj->isa('Math::Logic::Ternary::Expression') }) {
        print "# got ", as_string($subj), ", expected MLTE object\n";
        return 0;
    }
    my $s = as_string(val3($subj));
    my $v = as_string($val);
    if (defined $antival) {
        $s .= ' / not ' . as_string(val3(not3($subj)));
        $v .= ' / not ' . as_string($antival);
    }
    if ($s ne $v) {
        print "# got MLTE $s, expected MLTE $v\n";
        return 0;
    }
    return 1;
}

sub somesub { die }

ok(1);                                  # 1

my $false_a = not3('a');
ok(check($false_a, '', 'a'));           # 2

my $true_a  = not3($false_a);
ok(check($true_a, 'a', ''));            # 3

ok(check(not3(''), 1, ''));             # 4
ok(check(not3(0), 1, 0));               # 5
ok(check(not3(wrap('x')), '', 'x'));    # 6
ok(check(not3(wrap('')), 1, ''));       # 7
ok(check(not3(wrap(0)), 1, 0));         # 8
ok(check(not3(wrap( \&somesub )), '', \&somesub));  # 9

my $undef1 = not3(undef);
my $undef2 = not3(not3(undef));
my $undef3 = not3(wrap(undef));
my $undef4 = not3(not3(wrap(undef)));

ok(check($undef1, undef, undef));       # 10
ok(check($undef2, undef, undef));       # 11
ok(check($undef3, undef, undef));       # 12
ok(check($undef4, undef, undef));       # 13

ok(val3('x') eq 'x');                   # 14
ok(val3('') eq '');                     # 15
ok(!defined val3(undef));               # 16
ok(val3(\&somesub) == \&somesub);       # 17

ok(check(bool3($true_a),         1,     ''   ));  # 18
ok(check(bool3($false_a),        '',    1    ));  # 19
ok(check(bool3($undef1),         undef, undef));  # 20
ok(check(bool3('x'),             1,     ''   ));  # 21
ok(check(bool3(0),               '',    1    ));  # 22
ok(check(bool3(undef),           undef, undef));  # 23
ok(check(bool3(wrap('x')),       1,     ''   ));  # 24
ok(check(bool3(wrap(0)),         '',    1    ));  # 25
ok(check(bool3(wrap(undef)),     undef, undef));  # 26
ok(check(bool3(wrap(\&somesub)), 1,     ''   ));  # 27

my $false_b = not3('b');
my $true_b  = not3($false_b);

ok(check(and3($true_a,  $true_b),  'b',   ''   ));  # 28
ok(check(and3($true_a,  $false_b), '',    'b'  ));  # 29
ok(check(and3($true_a,  $undef2),  undef, undef));  # 30
ok(check(and3($false_a, $true_b),  '',    'a'  ));  # 31
ok(check(and3($false_a, $false_b), '',    'a'  ));  # 32
ok(check(and3($false_a, $undef2),  '',    'a'  ));  # 33
ok(check(and3($undef1,  $true_b),  undef, undef));  # 34
ok(check(and3($undef1,  $false_b), '',    'b'  ));  # 35
ok(check(and3($undef1,  $undef2),  undef, undef));  # 36

ok(check(or3($true_a,  $true_b),  'a',   ''   ));  # 37
ok(check(or3($true_a,  $false_b), 'a',   ''   ));  # 38
ok(check(or3($true_a,  $undef2),  'a',   ''   ));  # 39
ok(check(or3($false_a, $true_b),  'b',   ''   ));  # 40
ok(check(or3($false_a, $false_b), '',    'b'  ));  # 41
ok(check(or3($false_a, $undef2),  undef, undef));  # 42
ok(check(or3($undef1,  $true_b),  'b',   ''   ));  # 43
ok(check(or3($undef1,  $false_b), undef, undef));  # 44
ok(check(or3($undef1,  $undef2),  undef, undef));  # 45

ok(check(xor3($true_a,  $true_b),  '',    'b'  ));  # 46
ok(check(xor3($true_a,  $false_b), 'a',   ''   ));  # 47
ok(check(xor3($true_a,  $undef2),  undef, undef));  # 48
ok(check(xor3($false_a, $true_b),  'b',   ''   ));  # 49
ok(check(xor3($false_a, $false_b), '',    'b'  ));  # 50
ok(check(xor3($false_a, $undef2),  undef, undef));  # 51
ok(check(xor3($undef1,  $true_b),  undef, undef));  # 52
ok(check(xor3($undef1,  $false_b), undef, undef));  # 53
ok(check(xor3($undef1,  $undef2),  undef, undef));  # 54

ok(check(eqv3($true_a,  $true_b),  'b',   ''   ));  # 55
ok(check(eqv3($true_a,  $false_b), '',    'b'  ));  # 56
ok(check(eqv3($true_a,  $undef2),  undef, undef));  # 57
ok(check(eqv3($false_a, $true_b),  '',    'a'  ));  # 58
ok(check(eqv3($false_a, $false_b), 'b',   ''   ));  # 59
ok(check(eqv3($false_a, $undef2),  undef, undef));  # 60
ok(check(eqv3($undef1,  $true_b),  undef, undef));  # 61
ok(check(eqv3($undef1,  $false_b), undef, undef));  # 62
ok(check(eqv3($undef1,  $undef2),  undef, undef));  # 63

__END__
