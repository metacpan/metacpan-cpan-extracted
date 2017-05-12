
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print "1..0 # SKIP these tests are for testing by the author\n";
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/IRC/Message/Object.pm',
    'lib/IRC/Mode/Set.pm',
    'lib/IRC/Mode/Single.pm',
    'lib/IRC/Toolkit.pm',
    'lib/IRC/Toolkit/CTCP.pm',
    'lib/IRC/Toolkit/Case.pm',
    'lib/IRC/Toolkit/Case/MappedString.pm',
    'lib/IRC/Toolkit/Colors.pm',
    'lib/IRC/Toolkit/ISupport.pm',
    'lib/IRC/Toolkit/Masks.pm',
    'lib/IRC/Toolkit/Modes.pm',
    'lib/IRC/Toolkit/Numerics.pm',
    'lib/IRC/Toolkit/Parser.pm',
    'lib/IRC/Toolkit/Role/CaseMap.pm',
    'lib/IRC/Toolkit/TS6.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/00_load.t',
    't/00_load_selective.t',
    't/01_message_obj.t',
    't/02_util/case.t',
    't/02_util/colors.t',
    't/02_util/ctcp.t',
    't/02_util/isupport.t',
    't/02_util/mask.t',
    't/02_util/modes.t',
    't/02_util/numerics.t',
    't/02_util/parser.t',
    't/02_util/ts6.t',
    't/03_irc_mode.t',
    't/04_irc_modechange.t',
    't/05_role/casemap.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/release-cpan-changes.t',
    't/release-pod-linkcheck.t',
    't/release-unused-vars.t'
);

notabs_ok($_) foreach @files;
done_testing;
