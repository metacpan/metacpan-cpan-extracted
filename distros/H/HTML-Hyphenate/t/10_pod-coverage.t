# $Id: 10_pod-coverage.t 116 2009-08-02 20:43:55Z roland $
# $Revision: 116 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/elaine/trunk/HTML-Hyphenate/t/10_pod-coverage.t $
# $Date: 2009-08-02 22:43:55 +0200 (Sun, 02 Aug 2009) $

use strict;
use warnings;
use utf8;

use Test::More;
if ( !eval { require Test::Pod::Coverage; 1 } ) {
	plan skip_all => q{Test::Pod::Coverage required for testing POD coverage};
}
Test::Pod::Coverage::all_pod_coverage_ok();
