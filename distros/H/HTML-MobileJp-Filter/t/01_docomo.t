use strict;
use Test::Base;

use HTML::MobileJp::Filter;
use HTTP::MobileAgent;

plan tests => 1 * blocks;

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
=== DoCoMoCSS and DoCoMoGUID
--- user_agent
DoCoMo/1.0/D501i
--- config
filters:
  - module: DoCoMoCSS
    config:
      base_dir: t/
  - module: DoCoMoGUID
--- input
<html>
<head>
<link rel="stylesheet" href="/01_docomo/foo.css" />
</head>
<body>
<a href="/foo">foo</a>
<div class="title">bar</div>
</body>
</html>
--- expected
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//i-mode group (ja)//DTD XHTML i-XHTML(Locale/Ver.=ja/1.0) 1.0//EN" "i-xhtml_4ja_10.dtd">
<html>
<head>
<link rel="stylesheet" href="/01_docomo/foo.css"/>
</head>
<body style="background:orange">
<a href="/foo?guid=ON">foo</a>
<div class="title" style="color:red">bar</div>
</body>
</html>
