use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MarpaX/ESLIF/URI.pm',
    'lib/MarpaX/ESLIF/URI/_generic.pm',
    'lib/MarpaX/ESLIF/URI/_generic/RecognizerInterface.pm',
    'lib/MarpaX/ESLIF/URI/_generic/ValueInterface.pm',
    'lib/MarpaX/ESLIF/URI/file.pm',
    'lib/MarpaX/ESLIF/URI/ftp.pm',
    'lib/MarpaX/ESLIF/URI/http.pm',
    'lib/MarpaX/ESLIF/URI/https.pm',
    'lib/MarpaX/ESLIF/URI/mailto.pm',
    'lib/MarpaX/ESLIF/URI/tag.pm',
    'lib/MarpaX/ESLIF/URI/tel.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/file.t',
    't/http.t',
    't/mailto.t',
    't/tag.t',
    't/tel.t'
);

notabs_ok($_) foreach @files;
done_testing;
