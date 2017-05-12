#!perl 

# This tests the :all import tag.

use Test::More tests => 6;



BEGIN { use_ok 'Font::GlyphNames' => ":all" }
ok exists &$_, $_, for qw
	'name2str name2ord str2name ord2name ord2ligname';

