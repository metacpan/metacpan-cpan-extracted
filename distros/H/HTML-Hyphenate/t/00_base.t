# $Id: 00_base.t 114 2009-08-02 19:12:48Z roland $
# $Revision: 114 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/elaine/trunk/HTML-Hyphenate/t/00_base.t $
# $Date: 2009-08-02 21:12:48 +0200 (Sun, 02 Aug 2009) $

use strict;
use warnings;
use utf8;

use Test::More;
$ENV{TEST_AUTHOR} && eval { require Test::NoWarnings };

BEGIN {
    @MAIN::methods =
      qw(html style min_length min_pre min_post output_xml default_lang default_included classes_included classes_excluded hyphenated);
    plan tests => ( 4 + @MAIN::methods ) + 1;
    ok(1);
    use_ok('HTML::Hyphenate');
}
diag("Testing HTML::Hyphenate $HTML::Hyphenate::VERSION");
my $hyphen = new_ok('HTML::Hyphenate');

@HTML::Hyphenate::Sub::ISA = qw(HTML::Hyphenate);
TODO: {
    todo_skip 'Empty subclass of Class::Meta::Express issue', 1 if 1;
    my $hyphen_sub = new_ok('HTML::Hyphenate::Sub');
}

foreach my $method (@MAIN::methods) {
    can_ok( 'HTML::Hyphenate', $method );
}

my $msg = 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{TEST_AUTHOR};
}
$ENV{TEST_AUTHOR} && Test::NoWarnings::had_no_warnings();
