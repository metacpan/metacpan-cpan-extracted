use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/File/KeePass/KDBX.pm',
    'lib/File/KeePass/KDBX/Tie/Association.pm',
    'lib/File/KeePass/KDBX/Tie/AssociationList.pm',
    'lib/File/KeePass/KDBX/Tie/Binary.pm',
    'lib/File/KeePass/KDBX/Tie/CustomData.pm',
    'lib/File/KeePass/KDBX/Tie/CustomIcons.pm',
    'lib/File/KeePass/KDBX/Tie/Entry.pm',
    'lib/File/KeePass/KDBX/Tie/EntryList.pm',
    'lib/File/KeePass/KDBX/Tie/Group.pm',
    'lib/File/KeePass/KDBX/Tie/GroupList.pm',
    'lib/File/KeePass/KDBX/Tie/Hash.pm',
    'lib/File/KeePass/KDBX/Tie/Header.pm',
    'lib/File/KeePass/KDBX/Tie/Protected.pm',
    'lib/File/KeePass/KDBX/Tie/Strings.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/keepass-base.t',
    't/keepass-convert.t',
    't/keepass-kdbx.t',
    'xt/author/clean-namespaces.t',
    'xt/author/critic.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/minimum-version.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-coverage.t',
    'xt/author/pod-no404s.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/cpan-changes.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
