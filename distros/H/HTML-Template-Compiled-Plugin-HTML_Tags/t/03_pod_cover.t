# $Id: 03_pod_cover.t,v 1.1 2006/11/03 20:54:00 tinita Exp $
use blib; # for development

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;
plan tests => 1;
pod_coverage_ok( "HTML::Template::Compiled::Plugin::HTML_Tags", "HTC::Plugin::HTML_Tags is covered");

