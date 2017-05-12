# $Id: 15_spell.t 387 2010-12-21 19:41:17Z roland $
# $Revision: 387 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/elaine/trunk/HTML-Hyphenate/t/15_spell.t $
# $Date: 2010-12-21 20:41:17 +0100 (Tue, 21 Dec 2010) $

use strict;
use warnings;
use English;
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Spelling; };

if ($EVAL_ERROR) {
    my $msg = 'Test::Spelling required to check spelling of POD';
    plan( skip_all => $msg );
}

Test::Spelling::all_pod_files_spelling_ok();
