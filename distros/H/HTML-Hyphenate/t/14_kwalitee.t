# $Id: 14_kwalitee.t 114 2009-08-02 19:12:48Z roland $
# $Revision: 114 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/elaine/trunk/HTML-Hyphenate/t/14_kwalitee.t $
# $Date: 2009-08-02 21:12:48 +0200 (Sun, 02 Aug 2009) $

use strict;
use warnings;
use utf8;

use Test::More;

eval {
    require Test::Kwalitee;
    Test::Kwalitee->import( tests => [qw( -has_meta_yml)] );
};

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;
