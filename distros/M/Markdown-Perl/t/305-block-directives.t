use strict;
use warnings;
use utf8;

use Markdown::Perl;
use Test2::V0;

sub run {
  &Markdown::Perl::convert;
}

is(run(":::\ncontent\n:::"), "<div>\n<p>content</p>\n</div>\n", 'naked block');
is(run("::: block\ncontent\n:::"), "<div class=\"block\">\n<p>content</p>\n</div>\n", 'block with name');
is(run("::: {#block}\ncontent\n:::"), "<div id=\"block\">\n<p>content</p>\n</div>\n", 'block with id');
is(run("::: {.Block}\ncontent\n:::"), "<div class=\"Block\">\n<p>content</p>\n</div>\n", 'block with class');
is(run("::: {.block .other}\ncontent\n:::"), "<div class=\"block other\">\n<p>content</p>\n</div>\n", 'block with classes');
is(run("::: {key=value}\ncontent\n:::"), "<div data-key=\"value\">\n<p>content</p>\n</div>\n", 'block with data');
is(run("::: name {.block #id .other}\ncontent\n:::"), "<div id=\"id\" class=\"name block other\">\n<p>content</p>\n</div>\n", 'block with name, id, and classes');

is(run(":::: B1\n::: B2\ncontent\n:::\nrest\n::::\nend\n"), "<div class=\"b1\">\n<div class=\"b2\">\n<p>content</p>\n</div>\n<p>rest</p>\n</div>\n<p>end</p>\n", 'nested blocks');

like(warning { run("::: {#junk=junk}\n:::")  }, qr/Unused attribute content/, 'warn for junk attribute');
like(warning { run("::: [content]\n:::")  }, qr/Unused inline content/, 'warn for inline content');

is(run(":::\ncontent\n:::", use_directive_blocks => 0), "<p>:::\ncontent\n:::</p>\n", 'disable block directives');

is(run(":::::::: SPOILERS ::::::::\ncontent\n::::::::::::::::::::::::::"), "<div class=\"spoilers\">\n<p>content</p>\n</div>\n", 'fancy block');

done_testing;
