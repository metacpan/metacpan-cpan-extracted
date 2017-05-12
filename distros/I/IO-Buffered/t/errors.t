use strict;
use warnings;

use Test::More tests => 18;
use IO::Buffered;

eval { my $buffer = new IO::Buffered(Split => ""); };
cmp_ok($@, "=~", 'Split should be a string or regexp', "Split croaked on empty string");

eval { my $buffer = new IO::Buffered(Split => undef); };
cmp_ok($@, "=~", 'Split should be a string or regexp', "Split croaked on undef");

eval { my $buffer = new IO::Buffered(Split => {}); };
cmp_ok($@, "=~", 'Split should be a string or regexp', "Split croaked on hash ref");

eval { my $buffer = new IO::Buffered(Split => []); };
cmp_ok($@, "=~", 'Split should be a string or regexp', "Split croaked on array ref");

eval { my $buffer = new IO::Buffered(Regexp => ""); };
cmp_ok($@, "=~", 'Regexp should be a string or regexp', "Regexp croaked on empty string");

eval { my $buffer = new IO::Buffered(Regexp => undef); };
cmp_ok($@, "=~", 'Regexp should be a string or regexp', "regexp croaked on undef");

eval { my $buffer = new IO::Buffered(Regexp => {}); };
cmp_ok($@, "=~", 'Regexp should be a string or regexp', "regexp croaked on hash ref");

eval { my $buffer = new IO::Buffered(Regexp => []); };
cmp_ok($@, "=~", 'Regexp should be a string or regexp', "regexp croaked on array ref");

eval { my $buffer = new IO::Buffered(FixedSize => []); };
cmp_ok($@, "=~", 'FixedSize should be a number', "FixedSize croaked on array ref");

eval { my $buffer = new IO::Buffered(FixedSize => {}); };
cmp_ok($@, "=~", 'FixedSize should be a number', "FixedSize croaked on hash ref");

eval { my $buffer = new IO::Buffered(FixedSize => "string"); };
cmp_ok($@, "=~", 'FixedSize should be a number', "FixedSize croaked on string ref");

eval { my $buffer = new IO::Buffered(Size => undef); };
cmp_ok($@, "=~", 'Args should be an array reference', "Size croaked on undef");

eval { my $buffer = new IO::Buffered(Size => [0,0]); };
cmp_ok($@, "=~", 'Template should be a string', "Size croaked on template as number");

eval { my $buffer = new IO::Buffered(Size => [{},0]); };
cmp_ok($@, "=~", 'Template should be a string', "Size croaked on template as hash ref");

eval { my $buffer = new IO::Buffered(Size => [[],0]); };
cmp_ok($@, "=~", 'Template should be a string', "Size croaked on template as array ref");

eval { my $buffer = new IO::Buffered(Size => ["n", undef]); };
cmp_ok($@, "=~", 'Offset should be a number', "Size croaked on offset as undef");

eval { my $buffer = new IO::Buffered(Size => ["n", {}]); };
cmp_ok($@, "=~", 'Offset should be a number', "Size croaked on offset as hash ref");

eval { my $buffer = new IO::Buffered(Size => ["n", []]); };
cmp_ok($@, "=~", 'Offset should be a number', "Size croaked on offset as array ref");

