# $Id: 03_pod_cover.t 2 2007-07-08 06:18:31Z hagy $
use blib; # for development

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;
plan tests => 1;
pod_coverage_ok( "HTML::Template::Compiled::Plugin::Comma", "HTC::Plugin::Comma is covered");

