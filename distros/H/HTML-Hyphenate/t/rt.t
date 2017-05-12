# $Id: rt.t 387 2010-12-21 19:41:17Z roland $
# $Revision: 387 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/elaine/trunk/HTML-Hyphenate/t/rt.t $
# $Date: 2010-12-21 20:41:17 +0100 (Tue, 21 Dec 2010) $

use strict;
use warnings;
use utf8;
use Test::More tests => 1 + 2;
use Test::NoWarnings;

use HTML::Hyphenate;

my $hyphenator = HTML::Hyphenate->new();
$hyphenator->default_lang(q{da_dk});

is( $hyphenator->hyphenated(q{Selvbetjeningen}),
    q{Selv­be­tje­nin­gen}, q{RT#64114} );

my $msg = 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{TEST_AUTHOR};
}
$ENV{TEST_AUTHOR} && Test::NoWarnings::had_no_warnings();
