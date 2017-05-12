use strict;
use Test::Base;

use HTML::MobileJp::Filter;
use HTTP::MobileAgent;
use utf8;

if (-e 't/emoticon.yaml') {
    plan tests => 1 * blocks;
} else {
    plan skip_all => 't/emoticon.yaml not found';
}

filters {
    user_agent => [qw/ chomp /],
    config     => [qw/ yaml  /],
    input      => [qw/ chomp /],
    expected   => [qw/ chomp /],
};

run {
    my $block  = shift;
    
    my $filter = HTML::MobileJp::Filter->new($block->config);
    my $html   = $filter->filter(
        mobile_agent => HTTP::MobileAgent->new($block->user_agent),
        html         => $block->input,
    );
    
    is($html, $block->expected, $block->name);
};

__DATA__
=== fallback TypeCast image
--- user_agent
Mozilla/5.0
--- config
filters:
  - module: PictogramFallback::TypeCast
    config:
      emoticon_yaml: t/emoticon.yaml
      template: <img src="/img/emoticon/%s.gif" />
--- input eval
"<html>\x{E63E}\x{E309}\x{ECA2}</html>"
--- expected eval
"<html><img src=\"/img/emoticon/sun.gif\" />\x{E309}\x{ECA2}</html>"

=== fallback TypeCast image and fallback_name
--- user_agent
Mozilla/5.0
--- config
filters:
  - module: PictogramFallback::TypeCast
    config:
      emoticon_yaml: t/emoticon.yaml
      template: <img src="/img/emoticon/%s.gif" />
  - module: PictogramFallback
    config:
      template: %s
      params:
        - fallback_name
--- input eval
"<html>\x{E63E}\x{E309}\x{ECA2}</html>"
--- expected
<html><img src="/img/emoticon/sun.gif" />[WC](>３<)</html>

=== fallback TypeCast image and fallback_name_htmlescape
--- user_agent
Mozilla/5.0
--- config
filters:
  - module: PictogramFallback::TypeCast
    config:
      emoticon_yaml: t/emoticon.yaml
      template: <img src="/img/emoticon/%s.gif" />
  - module: PictogramFallback
    config:
      template: %s
      params:
        - fallback_name_htmlescape
--- input eval
"<html>\x{E63E}\x{E309}\x{ECA2}</html>"
--- expected
<html><img src="/img/emoticon/sun.gif" />[WC](&gt;３&lt;)</html>

=== put pictograms as an entity reference
--- user_agent
Mozilla/5.0
--- config
filters:
  - module: EntityReference
    config:
      force: 1
--- input
<html>&#xE63E;&#x51A8;</html>
--- expected eval
"<html>\x{E63E}&#x51A8;</html>"
