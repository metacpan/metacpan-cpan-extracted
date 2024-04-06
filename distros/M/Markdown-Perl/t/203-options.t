use strict;
use warnings;
use utf8;

use Markdown::Perl 'convert';
use Test2::V0;

is(convert("~abc~"), "<p><s>abc</s></p>\n", 'default');
is(convert("~abc~", mode => 'cmark'), "<p>~abc~</p>\n", 'set_mode');
is(convert("~abc~"), "<p><s>abc</s></p>\n", 'default_again');


my $p = Markdown::Perl->new();
is($p->convert("~abc~"), "<p><s>abc</s></p>\n", 'default_oo');
is($p->convert("~abc~", mode => 'cmark'), "<p>~abc~</p>\n", 'local_mode_oo');
is($p->convert("~abc~"), "<p><s>abc</s></p>\n", 'default_again_oo');
$p->set_mode('cmark');
is($p->convert("~abc~"), "<p>~abc~</p>\n", 'set_mode_oo');
is($p->convert("~abc~", mode => 'default'), "<p><s>abc</s></p>\n", 'local_override_oo');
is($p->convert("~abc~"), "<p>~abc~</p>\n", 'no_override_oo');
like(warning { $p->set_mode('default')  }, qr/Setting mode.*overriding/, 'set_mode_override_warns');
is($p->convert("~abc~"), "<p><s>abc</s></p>\n", 'default_again_oo');

done_testing;
