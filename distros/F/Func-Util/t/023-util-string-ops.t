#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Func::Util;

# Test trim
is(Func::Util::trim('  hello  '), 'hello', 'trim: removes both sides');
is(Func::Util::trim('  hello'), 'hello', 'trim: removes leading');
is(Func::Util::trim('hello  '), 'hello', 'trim: removes trailing');
is(Func::Util::trim('hello'), 'hello', 'trim: no change needed');
is(Func::Util::trim("\t\nhello\t\n"), 'hello', 'trim: removes tabs and newlines');

# Test ltrim
is(Func::Util::ltrim('  hello  '), 'hello  ', 'ltrim: removes leading only');
is(Func::Util::ltrim('  hello'), 'hello', 'ltrim: removes leading spaces');
is(Func::Util::ltrim('hello  '), 'hello  ', 'ltrim: no leading to remove');

# Test rtrim
is(Func::Util::rtrim('  hello  '), '  hello', 'rtrim: removes trailing only');
is(Func::Util::rtrim('hello  '), 'hello', 'rtrim: removes trailing spaces');
is(Func::Util::rtrim('  hello'), '  hello', 'rtrim: no trailing to remove');

# Test starts_with
ok(Func::Util::starts_with('hello world', 'hello'), 'starts_with: hello world starts with hello');
ok(Func::Util::starts_with('hello', 'hello'), 'starts_with: exact match');
ok(!Func::Util::starts_with('hello world', 'world'), 'starts_with: does not start with world');
ok(Func::Util::starts_with('hello', ''), 'starts_with: empty prefix matches');

# Test ends_with
ok(Func::Util::ends_with('hello world', 'world'), 'ends_with: hello world ends with world');
ok(Func::Util::ends_with('hello', 'hello'), 'ends_with: exact match');
ok(!Func::Util::ends_with('hello world', 'hello'), 'ends_with: does not end with hello');
ok(Func::Util::ends_with('hello', ''), 'ends_with: empty suffix matches');

# Test replace_all
is(Func::Util::replace_all('hello world', 'o', '0'), 'hell0 w0rld', 'replace_all: replaces all occurrences');
is(Func::Util::replace_all('aaa', 'a', 'b'), 'bbb', 'replace_all: replaces all a with b');
is(Func::Util::replace_all('hello', 'x', 'y'), 'hello', 'replace_all: no match, no change');

done_testing();
