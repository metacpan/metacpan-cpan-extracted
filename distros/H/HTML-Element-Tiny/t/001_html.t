use strict;
local $^W = 1;
use Test::More 'no_plan';
use HTML::Element::Tiny;

sub _e {
  return HTML::Element::Tiny->new(@_)
}
sub _h {
  return _e(@_)->as_HTML;
}

$HTML::Element::Tiny::HAS_HTML_ENTITIES = 0;

is(
  _h([ 'span' ]), qq{<span></span>}, "basic tag",
);
is(
  _h([ 'input' ]), qq{<input />}, "basic closed tag",
);
is(
  _h([ span => "foo" ]), qq{<span>foo</span>}, "text content",
);
is(
  _h([ span => [ 'input' ] ]), qq{<span><input /></span>}, "element content",
);
is(
  _h([ span => { id => "pie" }, "foo" ]), qq{<span id="pie">foo</span>},
  "id and content",
);
is(
  _h([ span => { class => "pie" }, "foo" ]), qq{<span class="pie">foo</span>},
  "class and content",
);
is(
  _h([ span => { class => "pie cake" }, "foo" ]),
  qq{<span class="pie cake">foo</span>},
  "classes and content",
);
is(
  _h(qq{<'foo' & "bar">}), "&lt;&apos;foo&apos; &amp; &quot;bar&quot;&gt;",
  "entity escaping: text segment"
);
is(
  _e([ 'span' ])->attr({ class => "pie cake" })->as_HTML,
  qq{<span class="pie cake"></span>},
  "class by attr()",
);
