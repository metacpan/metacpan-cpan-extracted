#!/usr/bin/perl -w

use strict;
use Test::More tests => 18;
use Devel::SizeMe ':all';
require Tie::Scalar;

{
    my $string = 'Perl Rules';
    my $before_size = total_size($string);
    is($string =~ /Perl/g, 1, 'It had better match');
    cmp_ok($before_size, '>', length $string,
	   'Our string has a non-zero length');
    cmp_ok(total_size($string), '>', $before_size,
	   'size increases due to magic');
}

SKIP: {
    # bug in perl added in blead by commit 815f25c6e302f84e, fixed in commit
    # f5c235e79ea25787, merged to maint-5.8 as 0710cc63c26afd0c and
    # 8298b2e171ce84cf respectively.
    skip("This triggers a formline assertion on $]", 4)
	if $] > 5.008000 && $] < 5.008003;
    my $string = 'Perl Rules';
    my $before_size = total_size($string);
    formline $string;
    my $compiled_size = total_size($string);
    cmp_ok($before_size, '>', length $string,
	   'Our string has a non-zero length');
    cmp_ok($compiled_size, '>', $before_size,
	   'size increases due to magic (and the compiled state)');
    # Not fully sure why (didn't go grovelling) but need to use a temporary to
    # avoid the magic being copied.
    $string = '' . $string;
    my $after_size = total_size($string);
    cmp_ok($after_size, '>', $before_size, 'Still larger than initial size');
    cmp_ok($after_size, '<', $compiled_size, 'size decreases due to unmagic');
}

{
    my $string = 'Perl Rules';
    my $before_size = total_size($string);
    cmp_ok($before_size, '>', length $string,
	   'Our string has a non-zero length');
    tie $string, 'Tie::StdScalar';
    my $after_size = total_size($string);
    cmp_ok($after_size, '>', $before_size, 'size increases due to magic');
    is($string, undef, 'No value yet');
    my $small_size = total_size($string);
    # This is defineately cheating, in that we're poking inside the
    # implementation of Tie::StdScalar, but if we just write to $string, the way
    # magic works, the (nice long) value is first written to the regular scalar,
    # then picked up by the magic. So it grows, which defeats the purpose of the
    # test.
    ${tied $string} = 'X' x 1024;
    cmp_ok(total_size($string), '>', $small_size + 1024,
	   'the magic object is counted');
}

SKIP: {
    skip("v-strings didn't use magic before 5.8.1", 2) if $] < 5.008001;
    my $v = eval 'v' . (0 x 1024);
    is($v, "\0", 'v-string is \0');
    cmp_ok(total_size($v), '>', 1024, 'total_size follows MG_PTR');
}

SKIP: {
    skip("no UTF-8 caching before 5.8.1", 5) if $] < 5.008001;
    my $string = "a\x{100}b";
    my $before_size = total_size($string);
    cmp_ok($before_size, '>', 0, 'Our string has a non-zero length');
    is(length $string, 3, 'length is sane');
    my $with_magic = total_size($string);
    cmp_ok($with_magic, '>', $before_size, 'UTF-8 caching fired and counted');
    is(index($string, "b"), 2, 'b is where we expect it');
    cmp_ok(total_size($string), '>', $with_magic,
	   'UTF-8 caching length table now present');
}
