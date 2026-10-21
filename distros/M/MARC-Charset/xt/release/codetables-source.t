#!perl
#
# Author/release-only check: is our vendored etc/codetables.xml still
# the same as what the Library of Congress currently publishes? This
# is diagnostic, not a build requirement -- MARC::Charset never
# fetches this URL itself, and a mismatch here is not necessarily a
# bug. See "DATA SOURCE" in MARC::Charset::Compiler's POD: the
# vendored copy carries maintainer corrections for known mistakes in
# LC's own data, so don't just copy a fresh download over
# etc/codetables.xml without checking those corrections are still
# needed.
#
# Only runs under RELEASE_TESTING, and skips cleanly (rather than
# failing) if the network, SSL support, or the URL itself isn't
# available -- most CI and CPAN Testers environments have none of
# those, and that's fine.

use strict;
use warnings;
use Test::More;

unless ($ENV{RELEASE_TESTING}) {
    plan skip_all => 'set RELEASE_TESTING=1 to run this (network-dependent) check';
}

eval { require HTTP::Tiny };
plan skip_all => 'HTTP::Tiny required to check the upstream source' if $@;

my $url = 'https://www.loc.gov/marc/specifications/codetables.xml';
my $local_file = 'etc/codetables.xml';

my $response = eval { HTTP::Tiny->new(timeout => 15)->get($url) };
plan skip_all => "couldn't reach $url: $@" if $@;
plan skip_all => "couldn't reach $url: $response->{status} $response->{reason}"
    unless $response->{success};

plan tests => 1;

open my $fh, '<:raw', $local_file or die "can't open $local_file: $!";
local $/;
my $local_content = <$fh>;
close $fh;

my $remote_content = $response->{content};

my $ok = ok($local_content eq $remote_content, "$local_file matches $url");

unless ($ok) {
    diag(sprintf(
        "%s (%d bytes) differs from the copy currently served at %s (%d bytes).\n" .
        "This is not automatically a problem -- see \"DATA SOURCE\" in " .
        "MARC::Charset::Compiler's POD before assuming the local copy is " .
        "the one that's wrong. To inspect the difference yourself:\n" .
        "    curl -s %s | diff - %s",
        $local_file, length($local_content), $url, length($remote_content),
        $url, $local_file
    ));
}
