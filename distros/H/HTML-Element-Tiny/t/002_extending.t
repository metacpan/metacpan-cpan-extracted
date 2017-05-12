use strict;
local $^W = 1;
use Test::More 'no_plan';
use HTML::Element::Tiny;

package My::Element;

BEGIN { use vars qw(@ISA); @ISA = 'HTML::Element::Tiny' }

use vars qw(%TAG_CLASS);
%TAG_CLASS = (
  a => '-a',
);

package My::Element::a;
BEGIN { use vars qw(@ISA); @ISA = 'My::Element' }
sub href { @_ > 1 ? shift->attr({ href => shift }) : shift->attr('href') }

package main;

my $elem = My::Element->new([ a => { href => "http://example.com" } ]);

isa_ok($elem, 'My::Element');
isa_ok($elem, 'My::Element::a');
can_ok($elem, 'href');
is($elem->href, "http://example.com");
is($elem->href("http://foo.com"), $elem);
is($elem->href, "http://foo.com");
is($elem->href, $elem->attr('href'));
is($elem->as_HTML, qq{<a href="http://foo.com"></a>});

$elem = My::Element->new([ 'span' ]);
isa_ok($elem, 'My::Element');
ok(! $elem->isa("My::Element::a"), "span is not isa 'a'");

isa_ok(My::Element->new("foo"), "HTML::Element::Tiny::Text");
{
  local $My::Element::TAG_CLASS{-text} = '-Text';
  isa_ok(My::Element->new("foo"), "My::Element::Text");
}
