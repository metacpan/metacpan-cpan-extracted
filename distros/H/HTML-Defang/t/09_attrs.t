#!/usr/bin/perl -w

BEGIN { # CPAN users don't have ME::*, so use eval
  eval 'use ME::FindLibs'
}

use strict;
use warnings;
use Test::More;
use HTML::Defang;

# These tests exercise the tag/attribute tokenizer against browser parsing
# quirks: '/' as an attribute separator, unusual whitespace, null bytes,
# backtick "quotes", unclosed/mismatched quotes, "=" soup, duplicate
# attributes, and resource-loading elements. HTML::Defang is not a full HTML5
# parser, so rather than matching the browser token-for-token it relies on a
# fail-safe property: anything it recognises as a tag has every attribute
# either whitelisted+validated or renamed with the defang_ prefix, and when
# its parser desyncs it breaks the tag or swallows the payload as a value.
#
# We verify that property with an independent real HTML tokenizer
# (HTML::Parser): after defanging, no start tag on any element may carry a
# live event handler or a javascript:/vbscript: URL on a URL attribute.

BEGIN {
  eval { require HTML::Parser; HTML::Parser->VERSION(3); 1 }
    or plan skip_all => 'HTML::Parser 3+ required for the browser-parse oracle';
}

my $D = HTML::Defang->new();
my %UrlAttr = map { $_ => 1 } qw(src href action background dynsrc lowsrc formaction data poster);

# Return the list of dangerous live attributes surviving in $html, ignoring
# defang_-renamed attributes (which browsers treat as inert unknown attrs).
sub live_attrs {
  my $html = shift;
  my @bad;
  my $p = HTML::Parser->new(api_version => 3, start_h => [ sub {
    my ($tag, $attr) = @_;
    for my $k (sort keys %$attr) {
      next if $k =~ /^defang_/i;
      push @bad, "$tag\[$k]"      if $k =~ /^on\w+/i;
      push @bad, "$tag\[$k=js]"   if $UrlAttr{lc $k} && $attr->{$k} =~ /^\s*(?:java|vb)script:/i;
    }
  }, "tagname, attr" ]);
  $p->parse($html); $p->eof;
  return @bad;
}

my @safe = (
  # slash separators / self-closing slash
  q{<img/onerror=alert(1)>},
  q{<img src=x /onerror=alert(1)>},
  q{<a/href=javascript:alert(1)>x</a>},
  # unusual whitespace between tag and attribute (incl. vertical tab)
  "<img\tonerror=alert(1)>",
  "<img\x0conerror=alert(1)>",
  "<img\x0bonerror=alert(1)>",
  # null bytes (stripped up front, so we defang the cleaned token)
  "<img src=x on\0error=alert(1)>",
  "<img src=jav\0ascript:alert(1)>",
  # backtick "quotes" and quote confusion
  q{<img src=`javascript:alert(1)`>},
  q{<img alt=`" onerror=alert(1)>},
  q{<img src="x'onerror='alert(1)">},
  q{<img src=x"y onerror=alert(1)>},
  # unclosed quotes and "=" soup
  q{<img src="x onerror=alert(1)>},
  q{<img = onerror=alert(1)>},
  q{<img src==javascript:alert(1)>},
  # entity-encoded scheme in a URL attribute
  q{<a href=&#106;avascript:alert(1)>x</a>},
  # duplicate attributes: browser uses the first
  q{<img src=javascript:alert(1) src=safe.png>},
  q{<img src=safe.png src=javascript:alert(1)>},
  q{<a href=safe.html href=javascript:alert(1)>x</a>},
  # resource-loading elements
  q{<input type=image src=javascript:alert(1)>},
  q{<object data=javascript:alert(1)>},
  q{<video><source onerror=alert(1)></video>},
);

plan tests => scalar(@safe) + 2;

for my $H (@safe) {
  my $Out = $D->defang($H);
  my @bad = live_attrs($Out);
  (my $show = $H) =~ s/([\x00-\x1f])/sprintf("\\x%02x",ord($1))/ge;
  ok(!@bad, "no live handler/url survives: $show")
    or diag("defanged output: $Out\nsurviving: @bad");
}

# Duplicate attributes explicitly: the first occurrence (what the browser uses)
# must be the one that survives, and if it is dangerous it must be defanged.
like($D->defang(q{<img src=safe.png src=javascript:alert(1)>}),
     qr/\bsrc=safe\.png/, "duplicate attr: first (safe) value is kept");
unlike($D->defang(q{<img src=javascript:alert(1) src=safe.png>}),
     qr/(?<!defang_)\bsrc\s*=\s*javascript:/i, "duplicate attr: first (dangerous) value is defanged");
