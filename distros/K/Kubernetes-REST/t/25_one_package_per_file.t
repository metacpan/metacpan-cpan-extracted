#!/usr/bin/env perl
# RewriteVersion and BumpVersionAfterRelease only rewrite the first "our
# $VERSION" per file. A second package in a file therefore keeps whatever
# version it was written with, silently, for every release after that - which
# is how five packages here sat at 1.003 until 1.106. One package per file
# keeps "the first" and "the only" the same thing.
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Find;
use Path::Tiny qw(path);

my $lib = path("$FindBin::Bin/../lib");

my @files;
find(sub { push @files, path($File::Find::name) if -f && /\.pm$/ }, "$lib");
@files = sort @files;

plan skip_all => 'no modules found' unless @files;

for my $file (@files) {
    my $rel = $file->relative($lib);
    my @packages = $file->slurp_utf8 =~ /^package\s+([\w:]+)/mg;

    is scalar @packages, 1, "$rel declares exactly one package"
        or diag "declares: @packages";
}

# The version everything must agree on comes from the main module.
my ($version) = path("$lib/Kubernetes/REST.pm")->slurp_utf8 =~ /^our \$VERSION = '([^']+)'/m;
ok $version, "main module has a version ($version)";

for my $file (@files) {
    my $rel = $file->relative($lib);
    my @versions = $file->slurp_utf8 =~ /^our \$VERSION = '([^']+)'/mg;

    is scalar @versions, 1, "$rel declares exactly one \$VERSION";
    is $versions[0], $version, "$rel is at $version";
}

done_testing;
