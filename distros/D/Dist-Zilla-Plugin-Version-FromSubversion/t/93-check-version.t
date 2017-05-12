#!perl

# Something has gone wrong in Dist::Zilla processing in release 1.000002
# https://metacpan.org/source/DOLMEN/Dist-Zilla-Plugin-Version-FromSubversion-1.000002/lib/Dist/Zilla/Plugin/Version/FromSubversion.pm#L3
# (maybe a bug in [PkgVersion], or a problem when doing release from the
#  Dist::Zilla::Shell)
#
# This test aims to detect that case by comparing the version number
# in the package to the version in META.json

use strict;
use warnings;
use Test::More ($ENV{RELEASE_TESTING} ? (tests => 6)
				      : (skip_all => 'only for release Kwalitee'));

SKIP: {
    ok(-f 'META.json', 'META.json exists')
	or skip "Missing META.json", 5;

    require_ok('JSON')
	or skip "Can't load JSON", 4;
    my $meta = do {
	local $/;
	open my $f, '<:utf8', 'META.json' or skip "Can't open META.json", 2;
	my $json = <$f>;
	JSON::decode_json($json);
    };

    require_ok('Dist::Zilla::Plugin::Version::FromSubversion');
    my $version = Dist::Zilla::Plugin::Version::FromSubversion->VERSION;
    cmp_ok $version, 'eq', $meta->{version}, "version from module matches META.json $meta->{version}";

    require_ok('ExtUtils::MakeMaker')
	or skip "Can't load EUMM", 1;
    cmp_ok $version, 'eq', MM->parse_version('lib/Dist/Zilla/Plugin/Version/FromSubversion.pm'), "version from module matches version parsed by EUMM";
}

