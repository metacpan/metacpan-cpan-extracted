use strict;
use warnings;
use utf8;

use Markdown::Perl 'convert';
use Test2::V0;

my $cb = '<input disabled="" type="checkbox">';

is(convert("- [ ] foo\n\n  [ ] bar", allow_task_list_markers => 'never'), "<ul>\n<li><p>[ ] foo</p>\n<p>[ ] bar</p>\n</li>\n</ul>\n", 'never');
is(convert("- [ ] foo\n\n  [ ] bar", allow_task_list_markers => 'list'), "<ul>\n<li><p>${cb} foo</p>\n<p>[ ] bar</p>\n</li>\n</ul>\n", 'list');
is(convert("- [ ] foo\n\n  [ ] bar", allow_task_list_markers => 'always'), "<ul>\n<li><p>${cb} foo</p>\n<p>${cb} bar</p>\n</li>\n</ul>\n", 'always');

done_testing;
