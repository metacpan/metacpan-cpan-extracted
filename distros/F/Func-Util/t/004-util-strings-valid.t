#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;


use_ok('Func::Util');
use Func::Util qw(
    is_empty starts_with ends_with
    trim ltrim rtrim
    replace_all
);

# ============================================
# is_empty - undefined or empty string
# ============================================

subtest 'is_empty basic' => sub {
    # Empty
    ok(is_empty(undef), 'is_empty: undef');
    ok(is_empty(''), 'is_empty: empty string');

    # Not empty
    ok(!is_empty(' '), 'is_empty: space');
    ok(!is_empty('hello'), 'is_empty: string');
    ok(!is_empty('0'), 'is_empty: string 0');
    ok(!is_empty(0), 'is_empty: number 0');
};

subtest 'is_empty edge cases' => sub {
    # Whitespace is not empty
    ok(!is_empty("\t"), 'is_empty: tab');
    ok(!is_empty("\n"), 'is_empty: newline');
    ok(!is_empty("  "), 'is_empty: multiple spaces');

    # References are not empty (not strings)
    ok(!is_empty([]), 'is_empty: empty array');
    ok(!is_empty({}), 'is_empty: empty hash');
};

# ============================================
# starts_with
# ============================================

subtest 'starts_with basic' => sub {
    ok(starts_with('hello world', 'hello'), 'starts_with: matches');
    ok(starts_with('hello world', 'h'), 'starts_with: single char');
    ok(starts_with('hello world', 'hello world'), 'starts_with: exact match');
    ok(starts_with('hello', ''), 'starts_with: empty prefix');

    ok(!starts_with('hello world', 'world'), 'starts_with: no match');
    ok(!starts_with('hello world', 'Hello'), 'starts_with: case sensitive');
    ok(!starts_with('hi', 'hello'), 'starts_with: prefix longer');
};

subtest 'starts_with edge cases' => sub {
    # Empty string
    ok(starts_with('', ''), 'starts_with: both empty');
    ok(!starts_with('', 'x'), 'starts_with: empty string, non-empty prefix');

    # Undef handling
    ok(!starts_with(undef, 'x'), 'starts_with: undef string');
    ok(!starts_with('x', undef), 'starts_with: undef prefix');
    ok(!starts_with(undef, undef), 'starts_with: both undef');

    # Special characters
    ok(starts_with('/path/to/file', '/'), 'starts_with: slash');
    ok(starts_with("line\nbreak", "line"), 'starts_with: with newline');
    ok(starts_with("\ttabbed", "\t"), 'starts_with: tab');

    # Unicode
    ok(starts_with("hello", "hello"), 'starts_with: ascii');
};

# ============================================
# ends_with
# ============================================

subtest 'ends_with basic' => sub {
    ok(ends_with('hello world', 'world'), 'ends_with: matches');
    ok(ends_with('hello world', 'd'), 'ends_with: single char');
    ok(ends_with('hello world', 'hello world'), 'ends_with: exact match');
    ok(ends_with('hello', ''), 'ends_with: empty suffix');

    ok(!ends_with('hello world', 'hello'), 'ends_with: no match');
    ok(!ends_with('hello world', 'World'), 'ends_with: case sensitive');
    ok(!ends_with('hi', 'hello'), 'ends_with: suffix longer');
};

subtest 'ends_with edge cases' => sub {
    # Empty string
    ok(ends_with('', ''), 'ends_with: both empty');
    ok(!ends_with('', 'x'), 'ends_with: empty string, non-empty suffix');

    # Undef handling
    ok(!ends_with(undef, 'x'), 'ends_with: undef string');
    ok(!ends_with('x', undef), 'ends_with: undef suffix');
    ok(!ends_with(undef, undef), 'ends_with: both undef');

    # Common file extensions
    ok(ends_with('file.txt', '.txt'), 'ends_with: .txt extension');
    ok(ends_with('file.tar.gz', '.gz'), 'ends_with: .gz extension');
    ok(ends_with('path/to/file.pm', '.pm'), 'ends_with: .pm extension');

    # Special characters
    ok(ends_with("line\n", "\n"), 'ends_with: newline');
    ok(ends_with("text\t", "\t"), 'ends_with: tab');
};

# ============================================
# trim - both sides
# ============================================

subtest 'trim basic' => sub {
    is(trim('  hello  '), 'hello', 'trim: both sides');
    is(trim('hello'), 'hello', 'trim: no whitespace');
    is(trim('  hello'), 'hello', 'trim: leading only');
    is(trim('hello  '), 'hello', 'trim: trailing only');
    is(trim(''), '', 'trim: empty string');
};

subtest 'trim whitespace types' => sub {
    is(trim("\thello\t"), 'hello', 'trim: tabs');
    is(trim("\nhello\n"), 'hello', 'trim: newlines');
    is(trim("\r\nhello\r\n"), 'hello', 'trim: crlf');
    is(trim(" \t\n hello \t\n "), 'hello', 'trim: mixed whitespace');
};

subtest 'trim edge cases' => sub {
    # All whitespace
    is(trim('   '), '', 'trim: only spaces');
    is(trim("\t\t\t"), '', 'trim: only tabs');
    is(trim("\n\n\n"), '', 'trim: only newlines');

    # Undef
    is(trim(undef), undef, 'trim: undef returns undef');

    # Internal whitespace preserved
    is(trim('  hello world  '), 'hello world', 'trim: internal space preserved');
    is(trim("  hello\tworld  "), "hello\tworld", 'trim: internal tab preserved');
    is(trim("  hello\nworld  "), "hello\nworld", 'trim: internal newline preserved');

    # Single character
    is(trim(' x '), 'x', 'trim: single char');
    is(trim('x'), 'x', 'trim: single char no space');
};

# ============================================
# ltrim - left side only
# ============================================

subtest 'ltrim basic' => sub {
    is(ltrim('  hello  '), 'hello  ', 'ltrim: preserves trailing');
    is(ltrim('hello'), 'hello', 'ltrim: no whitespace');
    is(ltrim('  hello'), 'hello', 'ltrim: leading only');
    is(ltrim('hello  '), 'hello  ', 'ltrim: trailing stays');
    is(ltrim(''), '', 'ltrim: empty string');
};

subtest 'ltrim whitespace types' => sub {
    is(ltrim("\thello"), 'hello', 'ltrim: tab');
    is(ltrim("\nhello"), 'hello', 'ltrim: newline');
    is(ltrim(" \t\nhello"), 'hello', 'ltrim: mixed');
};

subtest 'ltrim edge cases' => sub {
    is(ltrim(undef), undef, 'ltrim: undef');
    is(ltrim('   '), '', 'ltrim: only whitespace');
    is(ltrim("   hello\n"), "hello\n", 'ltrim: trailing newline preserved');
};

# ============================================
# rtrim - right side only
# ============================================

subtest 'rtrim basic' => sub {
    is(rtrim('  hello  '), '  hello', 'rtrim: preserves leading');
    is(rtrim('hello'), 'hello', 'rtrim: no whitespace');
    is(rtrim('  hello'), '  hello', 'rtrim: leading stays');
    is(rtrim('hello  '), 'hello', 'rtrim: trailing only');
    is(rtrim(''), '', 'rtrim: empty string');
};

subtest 'rtrim whitespace types' => sub {
    is(rtrim("hello\t"), 'hello', 'rtrim: tab');
    is(rtrim("hello\n"), 'hello', 'rtrim: newline');
    is(rtrim("hello \t\n"), 'hello', 'rtrim: mixed');
};

subtest 'rtrim edge cases' => sub {
    is(rtrim(undef), undef, 'rtrim: undef');
    is(rtrim('   '), '', 'rtrim: only whitespace');
    is(rtrim("\n   hello"), "\n   hello", 'rtrim: leading newline preserved');
};

# ============================================
# replace_all
# ============================================

subtest 'replace_all basic' => sub {
    is(replace_all('hello world', 'world', 'there'), 'hello there', 'replace_all: simple');
    is(replace_all('aaa', 'a', 'b'), 'bbb', 'replace_all: multiple occurrences');
    is(replace_all('hello', 'x', 'y'), 'hello', 'replace_all: no match');
    is(replace_all('hello', 'hello', 'hi'), 'hi', 'replace_all: full string');
};

subtest 'replace_all multiple occurrences' => sub {
    is(replace_all('ababab', 'ab', 'X'), 'XXX', 'replace_all: repeated pattern');
    is(replace_all('aaa', 'aa', 'X'), 'Xa', 'replace_all: overlapping - left to right');
    is(replace_all('1,2,3,4', ',', ' - '), '1 - 2 - 3 - 4', 'replace_all: commas');
};

subtest 'replace_all edge cases' => sub {
    # Empty strings
    is(replace_all('', 'x', 'y'), '', 'replace_all: empty source');
    is(replace_all('hello', '', 'x'), 'hello', 'replace_all: empty search');
    is(replace_all('hello', 'l', ''), 'heo', 'replace_all: empty replacement');

    # Expansion
    is(replace_all('abc', 'b', '123'), 'a123c', 'replace_all: expansion');

    # Contraction
    is(replace_all('hello world', 'world', 'W'), 'hello W', 'replace_all: contraction');

    # Case sensitivity
    is(replace_all('Hello hello HELLO', 'hello', 'X'), 'Hello X HELLO', 'replace_all: case sensitive');

    # Special regex chars (should be literal)
    is(replace_all('a.b.c', '.', '-'), 'a-b-c', 'replace_all: literal dot');
    is(replace_all('a*b*c', '*', '-'), 'a-b-c', 'replace_all: literal star');
    is(replace_all('a+b+c', '+', '-'), 'a-b-c', 'replace_all: literal plus');
    is(replace_all('a[b]c', '[b]', 'X'), 'aXc', 'replace_all: literal brackets');
    is(replace_all('a(b)c', '(b)', 'X'), 'aXc', 'replace_all: literal parens');
    is(replace_all('a\\bc', '\\', '/'), 'a/bc', 'replace_all: literal backslash');
};

subtest 'replace_all with special content' => sub {
    # Newlines
    is(replace_all("a\nb\nc", "\n", ' '), 'a b c', 'replace_all: newlines');

    # Tabs
    is(replace_all("a\tb\tc", "\t", ','), 'a,b,c', 'replace_all: tabs');

    # Replace with special chars
    is(replace_all('abc', 'b', "\n"), "a\nc", 'replace_all: insert newline');
    is(replace_all('abc', 'b', "\t"), "a\tc", 'replace_all: insert tab');
};

done_testing;
