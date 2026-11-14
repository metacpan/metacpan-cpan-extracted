use strict;
use warnings;

use Test::More;

my @modules = qw(
    InternetData
    InternetData::AsnResult
    InternetData::Bogon
    InternetData::Bogons
    InternetData::Cache
    InternetData::Database
    InternetData::DomainResult
    InternetData::Error
    InternetData::Oauth
    InternetData::OauthError
    InternetData::Result
);

use_ok($_) for @modules;

# Makefile.PL takes the distribution version from InternetData.pm alone, so a
# module left behind would ship indexed at the wrong version. A forgotten bump is
# a test failure rather than a bad release.
my $version = InternetData->VERSION;
ok($version, "the distribution version is $version");
# The two refusal subclasses live in OauthError.pm, so they are loaded, not used.
my @packages = (@modules, qw(InternetData::OauthAccessDeniedError InternetData::OauthExpiredTokenError));
# The bogon table is generated, and carries no version of its own.
is($_->VERSION, $version, "$_ is at $version") for grep { $_ ne 'InternetData::Bogons' } @packages;

done_testing();
