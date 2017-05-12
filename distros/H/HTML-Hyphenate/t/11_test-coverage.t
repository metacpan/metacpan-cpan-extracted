# $Id: 11_test-coverage.t 387 2010-12-21 19:41:17Z roland $
# $Revision: 387 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/elaine/trunk/HTML-Hyphenate/t/11_test-coverage.t $
# $Date: 2010-12-21 20:41:17 +0100 (Tue, 21 Dec 2010) $

use strict;
use warnings;
use utf8;

use Test::More;
if ( !eval { require Test::TestCoverage; 1 } ) {
	plan skip_all => q{Test::TestCoverage required for testing test coverage};
}
plan tests => 1;
Test::TestCoverage::test_coverage("HTML::Hyphenate");

my $obj = HTML::Hyphenate->new();
$obj->html(q{<p>hyphenated hyphenation</p>});
$obj->style(q{german});
$obj->min_length(10);
$obj->min_pre(2);
$obj->min_post(2);
$obj->output_xml(1);
$obj->default_lang(q{en_US});
$obj->default_included(1);
$obj->classes_included([qw(foo bar)]);
$obj->classes_excluded([qw(baz qu)]);
$obj->hyphenated();

Test::TestCoverage::ok_test_coverage('HTML::Hyphenate');
