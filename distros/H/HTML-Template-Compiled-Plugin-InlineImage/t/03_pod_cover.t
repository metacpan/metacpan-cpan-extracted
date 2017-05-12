# $Id: 03_pod_cover.t,v 1.1 2006/08/26 15:04:22 tinita Exp $
use blib; # for development

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;
plan tests => 1;
pod_coverage_ok( "HTML::Template::Compiled::Plugin::InlineImage", "HTC::Plugin::InlineImage is covered");

