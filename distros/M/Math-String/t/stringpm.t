#!/usr/bin/perl -w

use strict;
use Test::More;

BEGIN
{
    $| = 1;
    chdir 't' if -d 't';
    unshift @INC, '../blib/arch';
    unshift @INC, '../lib';     # to run manually
    plan tests => 266;
}

use Math::String;
use Math::BigInt;

my (@args, $try, $rc, $x, $y, $z, $i);
$| = 1;
while (<DATA>) {
    chop;
    @args = split(/:/, $_, 99);

    # print join(' ', @args), "\n";
    # test String => Number
    $try = "\$x = Math::String->new('$args[0]', [ $args[1] ])->bstr()";
    $rc = eval $try;

    # stringify returns undef instead of NaN
    if ($args[2] eq 'NaN') {
        is($rc, undef, $try);
    } else {
        is("$rc", $args[2], $try);
    }

    # test Number => String
    next if $args[2] eq 'NaN';  # dont test NaNs reverse
    $try = "\$x = Math::String::from_number('$args[3]', [ $args[1] ]);";

    $rc = eval $try;
    is("$rc", "$args[0]", $try);

    # test output as_number()
    if (defined $args[3]) {
        $try = "\$x = Math::String->new('$args[0]', [ $args[1] ])->as_number()";
        $rc = eval $try;
        is("$rc", $args[3], $try);
    }
    # test is_valid()
    $try  = "\$x = Math::String->new('$args[0]', [ $args[1] ]);";
    $try .= "\$x = \$x->is_valid();";
    $rc = eval $try;
    is("$rc", 1, $try);
}
close DATA;

##############################################################################
# check whether cmp and <=> work
$x = Math::String->new('a');            # 1
$y = Math::String->new('z');            # 26
$z = Math::String->new('a');            # 1 again

is($x < $y,   1,  '$x < $y');           # is(1 < 26, 1)
is($x > $y,  '',  '$x > $y');           # is(1 > 26, '')
is($x <=> $y, -1, '$x <=> $y');         # is(1 <=> 26, -1)
is($y <=> $x,  1, '$y <=> $x');         # is(26 <=> 1, 1)
is($x <=> $x,  0, '$x <=> $x');         # is(1 <=> 1, 1)
is($x <=> $z,  0, '$x <=> $z');         # is(1 <=> 1, 1)

is($x lt $y,   1, '$x lt $y');          # is('a' lt 'z', 1);
is($x gt $y,  '', '$x gt $y');          # is('z' lt 'a', '');
is($x cmp $y, -1, '$x cmp $y');         # is('a' cmp 'z', -1);
is($y cmp $x,  1, '$y cmp $x');         # is('z' cmp 'a', 1);
is($x cmp $x,  0, '$x cmp $x');
is($x cmp $z,  0, '$x cmp $z');

# overloading of <, <=, =>, >, <=>, ==, !=
$x = Math::String->new('a');
is($x == "a", 1, '$x == "a"');
is($x != "",  1, '$x != ""');

##############################################################################
# check if negative numbers give same output as positives
$try = "\$x = Math::String::from_number(-12, ['0'..'9']); \$x->as_number();";
$rc = eval $try;
is("$rc", '-12', $try);
$try  = '$x = Math::String::from_number(-12, ["0".."9"]);';
$try .= '$y = Math::String::from_number(12, ["0".."9"]); "true" if "$x" eq "$y";';
$rc = eval $try;
is("$rc", 'true', $try);

##############################################################################
# check whether ++ and -- work

$try  = '$x = Math::String->new("z", ["a".."z"]);';
$try .= '$y = $x; $y++; "true" if $x < $y;';

$rc = eval $try;
is("$rc", 'true', $try);

$try  = '$x = Math::String->new("z", ["a".."z"]);';
$try .= '$y = $x; $y++; $y--; "true" if $x == $y;';
$rc = eval $try;
is("$rc", 'true', $try);

###############################################################################
# stress-test ++ and -- since they use caching

# compare to build in ++
$x = Math::String->new('');
is($x, '');
$a = 'a';
for ($i = 0; $i < 27; $i++) {
    is(++$x, $a++);
}

# inc/dec with sep chars
$x = Math::String->new('',
                       Math::String::Charset->new({ start => ['foo', 'bar', 'baz' ],
                                                    sep => ' ' }));
is($x, '');
is(++$x, 'foo');
is(++$x, 'bar');
is(++$x, 'baz');
is(++$x, 'foo foo');
is(++$x, 'foo bar');
is(++$x, 'foo baz');
is(++$x, 'bar foo');
is(++$x, 'bar bar');
is($x, 'bar bar');
is(--$x, 'bar foo');
is(--$x, 'foo baz');
is(--$x, 'foo bar');
is(--$x, 'foo foo');
is(--$x, 'baz');
is(--$x, 'bar');
is(--$x, 'foo');
is(--$x, '');
is(--$x, 'foo');                 # -1, negative
is(--$x, 'bar');                 # -2, negative
is(--$x, 'baz');                 # -3, negative
is(--$x, 'foo foo');            # -4, negative
is(--$x, 'foo bar');            # -5, negative
is(--$x, 'foo baz');            # -6, negative
is(--$x, 'bar foo');            # -7, negative
is(--$x, 'bar bar');            # -8, negative
is(--$x, 'bar baz');            # -9, negative
is(--$x, 'baz foo');            # -10, negative
is(--$x, 'baz bar');            # -11, negative
is(--$x, 'baz baz');            # -12, negative
is(--$x, 'foo foo foo');         # -13, negative
is(--$x, 'foo foo bar');         # -14, negative
is(--$x, 'foo foo baz');         # -15, negative
is(--$x, 'foo bar foo');         # -16, negative

# for minlen
$x = Math::String->new('',
                       Math::String::Charset->new({ start => ['a', 'b', 'c' ],
                                                    minlen => 2, }));
ok_undef($x);

$x = Math::String->new('aa',
                       Math::String::Charset->new({ start => ['a', 'b', 'c' ],
                                                    minlen => 2, }));
is($x, 'aa');		# smallest possible
ok_undef(--$x);

##############################################################################
# extended tests for inc/dec with sep chars

$x = Math::String->new('',
                       Math::String::Charset->new({ start => ['foo', 'bar',
                                                              'baz', 'bon',
                                                              'bom' ],
                                                    sep => ' ' }));
is($x, '');
is(++$x, 'foo');
is(++$x, 'bar');
is(++$x, 'baz');
is(++$x, 'bon');
is(++$x, 'bom');
is(++$x, 'foo foo');
is(++$x, 'foo bar');
is(++$x, 'foo baz');
is(++$x, 'foo bon');
is(++$x, 'foo bom');
is(++$x, 'bar foo');
is(++$x, 'bar bar');

is(--$x, 'bar foo');
is(--$x, 'foo bom');
is(--$x, 'foo bon');
is(--$x, 'foo baz');
is(--$x, 'foo bar');
is(--$x, 'foo foo');
is(--$x, 'bom');
is(--$x, 'bon');
is(--$x, 'baz');
is(--$x, 'bar');
is(--$x, 'foo');
is(--$x, '');                   # 0

is(--$x, 'foo');
is(--$x, 'bar');
is(--$x, 'baz');
is(--$x, 'bon');
is(--$x, 'bom');
is(--$x, 'foo foo');
is(--$x, 'foo bar');
is(--$x, 'foo baz');
is(--$x, 'foo bon');
is(--$x, 'foo bom');
is(--$x, 'bar foo');
is(--$x, 'bar bar');

# next() for negative strings:

is(++$x, 'bar foo');
is(++$x, 'foo bom');
is(++$x, 'foo bon');
is(++$x, 'foo baz');
is(++$x, 'foo bar');
is(++$x, 'foo foo');
is(++$x, 'bom');
is(++$x, 'bon');
is(++$x, 'baz');
is(++$x, 'bar');

##############################################################################
# check whether bior(), bxor(), band() word
$x = Math::String->new("a");
$y = Math::String->new("b");
$z = $y | $x;
is("$z", 'c', '$z = $y | $x');

$x = Math::String->new("b");
$y = Math::String->new("c");
$z = $y & $x;
is("$z", 'b', '$z = $y & $x');

$x = Math::String->new("d");
$y = Math::String->new("e");
$z = $y ^ $x;
is("$z", 'a', '$z = $y ^ $x');

##############################################################################
# check objectify of additional params

$x = Math::String->new('x');
$x->badd('a');                  # 24 +1

is($x->as_number(), 25);
$x->badd(1);                    # can't add numbers
                                # ('1' is not a valid Math::String here!)
is($x->as_number(), 'NaN');

is($x->order(), 1);            # SIMPLE

$x = Math::String->new('x');
$x->badd(Math::BigInt->new(1)); # 24 +1 = 25
is($x, 'y');

###############################################################################
# check if new() strips additional sep chars at front/end before caching

foreach (' foo bar ', 'foo bar ', ' foo bar') {
    $try  = "\$x = Math::String->new('$_', ";
    $try .= ' { sep => " ", start => ["foo", "bar"] }); "$x";';
    $rc = eval $try;
    is("$rc", 'foo bar', $try);
}

##############################################################################
# check if output of bstr is again a valid Math::String
for ($i = 1; $i<42; $i++) {
    $try  = "\$x = Math::String::from_number($i, ['0'..'9']);";
    $try .= "\$x = Math::String->new(\"\$x\", ['0'..'9'])->as_number();";
    $rc = eval $try;
    is("$rc", $i, $try);
}

##############################################################################
# check overloading of cmp

$try = "\$x = Math::String->new('a'); 'true' if \$x eq 'a';";
$rc = eval $try;
is("$rc", "true", $try);

# check whether cmp works for other objects
$try  = "\$x = Math::String->new('00', ['0'..'9']);";
$try .= "\$y = Math::BigInt->new('10');";
$try .= "'false' if \$x ne \$y;";
$rc = eval $try;
is("$rc", "false", $try);

##############################################################################
# check $string->length()

$try = "\$x = Math::String->new('abcde'); \$x->length();";
$rc = eval $try;
is("$rc", 5, $try);

$try = "\$x = Math::String->new('foo bar foo ', ";
$try .= " { sep => ' ', start => ['foo', 'bar'] }); \$x->length();";
$rc = eval $try;
is("$rc", 3, $try);

$try = "\$x = Math::String->new('foo bar ', ";
$try .= ' { sep => " ", start => ["foo", "bar"] }); "$x";';
$rc = eval $try;
is("$rc", 'foo bar', $try);

$try = "\$x = Math::String->new('foobarfoo', ['foo', 'bar']); \$x->length();";
$rc = eval $try;
is("$rc", 3, $try);

$try = "\$x = Math::String->new(''); \$x->length();";
$rc = eval $try;
is("$rc", 0, $try);

##############################################################################
# as_number

$x = Math::String->new('abc');
is(ref($x->as_number()), 'Math::BigInt');

##############################################################################
# numify

$x = Math::String->new('abc');
is(ref($x->numify()), '');
is($x->numify(), 731);

##############################################################################
# bzero, binf, bnan, bone

$x = Math::String->new('abc');
$x->bzero();
is(ref($x), 'Math::String');
is($x, '');
is($x->sign(), '+');

$x = Math::String->new('abc');
$x->bnan();
is(ref($x), 'Math::String');
is($x->bstr(), undef);
is($x->sign(), 'NaN');

$x = Math::String->new('abc');
$x->binf();
is(ref($x), 'Math::String');
is($x->bstr(), undef);
is($x->sign(), '+inf');

$x = Math::String::bzero();
is(ref($x), 'Math::String');
is($x, '');
is($x->sign(), '+');

$x = Math::String::bnan();
is(ref($x), 'Math::String');
is($x->bstr(), undef);
is($x->sign(), 'NaN');

$x = Math::String::binf();
is(ref($x), 'Math::String');
is($x->bstr(), undef);
is($x->sign(), '+inf');

$x = Math::String::bone();
is(ref($x), 'Math::String');
is($x->bstr(), 'a');
is($x->sign(), '+');

$x = Math::String::bone(undef, ['z'..'a']);
is(ref($x), 'Math::String');
is($x->bstr(), 'z');
is($x->sign(), '+');

##############################################################################
# accuracy/precicison

is($Math::String::accuracy, undef);
is($Math::String::precision, undef);
is($Math::String::div_scale, 0);
is($Math::String::round_mode, 'even');

##############################################################################
# new({ str => 'aaa', num => 123 });

$x = Math::String->new({ str => 'aaa', num => 123 });
is($x, 'aaa');
is($x->as_number(), 123);
is($x->is_valid(), 1);
# invalid matching string form is updated (not via ++, since this invalidates
# the cache, and thus syncronizes the two representations)
# This is actually a test of a mis-feature, something that shouldn't work since
# the string is invalid in the first place
$x += 'a';
is($x->as_number(), 124);
is($x, 'dt');

# first/last
$x = Math::String->new('abc');
is($x->first(1), 'a');
is($x->first(2), 'aa');
is($x->last(1), 'z');
is($x->last(2), 'zz');
# -> and :: syntax
is(Math::String->first(3), 'aaa');
is(Math::String->last(3), 'zzz');
# -> and :: with different charset
is(Math::String->last(3, [reverse 'a'..'z']), 'aaa');
is(Math::String->last(3, [reverse 'a'..'z']), 'aaa');

# check error()
$x = Math::String->new({ str => 'aaa', num => 123 });
is($x->error(), '');

###############################################################################
# class()

$x = Math::String->new('abc');
is($x->class(3), 26*26*26);
is($x->class(0), 1);

###############################################################################
# copy() bug with not sharing charset (and inc)

my $cs = Math::String::Charset->new({
                                     sets => {
                                               '0' => ['a'..'f'],
                                               '1' => ['a'..'f', 'A'..'F'],
                                              '-1' => ['a'..'f', '0'..'3', '!', '.', '?'],
                                              '-2' => ['a'..'f', '0'..'3', '!', '.', '?'],
                                             },
                                    });

$x = Math::String->new('F?', $cs);
is(++$x, 'aaa');
is(--$x, 'F?');
#$x = Math::String->new('', $cs); $x += 'F?';
#is($x, 'F?');

###############################################################################
# scale() and related stuff

$x = Math::String->new('a');
is($x->{_scale}, undef);
$x->scale(12);
is($x->{_set}->{_scale}, 12);
# not changed:
is($x->bstr(), "a");
is("$x", "a");
# scaled:
is($x->as_number(), 12);
$x++;
is($x->as_number(), 24);
is("$x", 'b');

$x = Math::String::from_number(2, ['a'..'z']);
is($x->as_number(), 2);
is("$x", 'b');

$cs = Math::String::Charset->new(['a'..'z']);
$cs->scale(123);

$x = Math::String::from_number(0, $cs);
is($x->as_number(), 0);
is($x, '');

$x = Math::String::from_number(123, $cs);
is($x->as_number(), 123);
is($x, 'a');

$x = Math::String::from_number(246, $cs);
is($x->as_number(), 246);
is($x, 'b');

$x = Math::String::from_number(122, $cs);
is($x->as_number(), 0);
is($x, '');

$x = Math::String::from_number(124, $cs);
is($x->as_number(), 123);
is($x, 'a');

# test that new() => "str, number" => new(str => ..., num => ...) works
$x = Math::String->new('abc', $cs);
my $str = $x->bstr();
my $num = $x->as_number();
$y = Math::String->new({ str => $x->bstr(),
                         num => $x->as_number() },
                       $cs);
is("$x", "$y");
is($x->as_number(), $y->as_number());

$x->binc();
$y->binc();

is("$x", "$y");
is($x->as_number(), $y->as_number());

# all done

###############################################################################
# Perl 5.005 does not like ok ($x,undef)

sub ok_undef {
    my $x = shift;

    if (ref($x)) {
        $x = $x->bstr();
    }

    if (!defined $x) {
        pass();
        return 1;
    }

    is($x, 'undef');
    return 0;
}

1;

__DATA__
abc:'0'..'9':NaN
abc:'a'..'b':NaN
abc:'a'..'c':abc:18
