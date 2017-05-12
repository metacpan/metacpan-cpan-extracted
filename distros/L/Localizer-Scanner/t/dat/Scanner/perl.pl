#!/usr/bin/env perl

use strict;
use warnings;

print q{_("123")};
print q{_("[_1] is happy")};
print q{_("%1 is happy")};
print q{_("[*,_1] counts")};
print q{_("%*(%1) counts")};
print q{_("[*,_1,_2] counts")};
print q{_("[*,_1,_2] counts")};
print q{_('foo\$bar')};
print q{_("foo\$bar")};
print q{_('foo\x20bar')};
print q{_("foo\x20bar")};
print q{_('foo\nbar')};
print q{_("foo\nbar")};
print qq{_("foo\nbar")};
print q{_("foo\nbar")};
print qq{_("foobar\n")};
print q{_('foo\bar')};
print q{_('foo\\\\bar')};
print q{_("foo\bar")};
print q{l( 'foo "bar" baz' )};
print q{[% loc( 'foo "bar" baz' ) %]};
print q{_(q{foo bar})};
print q{_(q{foo\bar})};
print q{_(q{foo\\\\bar})};
print q{_('foo\bar')};
print q{_('foo\\\\bar')};
print q{_("foo\bar")};
print q{l( 'foo "bar" baz' );};
print q{[% loc( 'foo "bar" baz' ) %]};
print q{_(q{foo bar})};
print q{_(q{foo\bar})};
print q{_(q{foo\\\\bar})};
print q{_(qq{foo\bar})};
print q{my $x = loc('I "think" you\'re a cow.') . "\n";};
print q{my $x = loc("I'll poke you like a \"cow\" man.") . "\n";};
print q{_("","car")};
print q{_("0")};

print <<'__EXAMPLE__';
_(<<__LOC__);
123
__LOC__
__EXAMPLE__

print <<'__EXAMPLE__';
_(<<'__LOC__');
foo\$bar\'baz
__LOC__
__EXAMPLE__

print <<'__EXAMPLE__';
_(<<"__LOC__");
foo\$bar
__LOC__
__EXAMPLE__

print <<'__EXAMPLE__';
_(<<__LOC__);
foo
bar
__LOC__
__EXAMPLE__

print <<'__EXAMPLE__';
_(<<"");
example

__EXAMPLE__

print <<'__EXAMPLE__';
_(<<__LOC__
example
__LOC__
);
__EXAMPLE__
