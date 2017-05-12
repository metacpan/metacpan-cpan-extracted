# $Id: 03_pod_cover.t 5 2007-07-14 15:28:44Z root $
use blib; # for development

use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;
plan tests => 1;
pod_coverage_ok( "HTML::Template::Compiled::Plugin::LineBreak", "HTC::Plugin::LineBreak is covered");

