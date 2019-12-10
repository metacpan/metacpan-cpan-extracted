# Copyright (c) 2009-2019 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Checking if $VERSION strings of updated perl modules have been updated.
# These are tests for the distribution maintainer.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/95_versions.t'

use 5.006;
use strict;
use warnings;
use Test;
use lib 't/lib';
use Test::MyUtils;

BEGIN {
    use_or_bail('File::Spec');
    maintainer_only();
}

my $known_versions_file = File::Spec->catfile(qw(t data KNOWN_VERSIONS));
my %known_versions = ();

if (open KV, '<', $known_versions_file) {
    local $/ = "\n";
    my $line_no = 0;
    while (<KV>) {
        ++$line_no;
        next if /^\s*(?:#.*)?$/;        # ignore comments
        if (/^\s*(\S+)\s+(\S+)\s+([a-f0-9]+)\s+(.*?)\s*$/) {
            my ($version, $type, $checksum, $file) = ($1, $2, $3, $4);
            if (exists $known_versions{$file}->{$version}->{$type}) {
                my $old = $known_versions{$file}->{$version}->{$type};
                print
                    q[# ], $old eq $checksum? 'duplicate': 'conflicting',
                    " entries in $known_versions_file ",
                    "for $file version $version!\n";
            }
            $known_versions{$file}->{$version}->{$type} = $checksum;
        }
        else {
            print "# bogus entry in $known_versions_file, line $line_no\n";
        }
    }
    close KV;
}

my %checksums = ();

my $manifest  = Test::MyUtils::slurp_or_bail('MANIFEST');
my @pm_files  = $manifest =~ /^(.+\.pm)$/mgi;

my $signature = Test::MyUtils::slurp_or_bail('SIGNATURE');

if (
    $signature =~ m{
        ^-----BEGIN\s+PGP\s+SIGNED\s+MESSAGE-----\n
        Hash:\s+\S+\n
        \n
        (.*)
        ^-----BEGIN\s+PGP\s+SIGNATURE-----\n
    }msx
) {
    my $checksums_txt = $1;
    while ($checksums_txt =~ m/^(\w+) ([a-f\d]+)\s+(.*)$/mgo) {
        $checksums{$3} = [$1, $2];
    }
}
else {
    print "1..0 # SKIP cannot parse signature file\n";
    exit;
}

plan(tests => 1 + 6 * @pm_files);

ok(0 < @pm_files);
foreach my $file (@pm_files) {
    my $module = $file;
    $module =~ s{(?:t/)?lib/}{};
    $module =~ s{\.pm\z}{}i;
    $module =~ s{/}{::}g;
    print "# checking $module\n";

    my $version = eval "require $module; " . '$' . $module . '::VERSION';
    ok(defined $version);
    $version = '0' if !defined $version;

    my $sane = eval { use warnings FATAL => 'all'; 0 <= $version };
    if (!defined $sane) {
        my $err = $@;
        $err =~ s/\n.*//s;
        print "# strange version: $version: $err\n";
    }
    ok($sane);

    my $documented = '';
    if (open PM_FILE, '<', $file) {
        local $/ = \262144;
        my $content = <PM_FILE>;
        close PM_FILE;
        if (
            defined($content) &&
            $content =~ m{
                \n
                =head\d\s+VERSION\n
                \n
                [^\n]*\s[Vv]ersion\s+
                (\d\S*)\s
            }mx
        ) {
            $documented = $1;
            if ($version ne $documented) {
                print
                    '# $', $module, '::VERSION is ', $version,
                    ' while POD version is ', $documented, "\n";
            }
        }
    }
    skip($documented? 0: 'version not found in POD', $version eq $documented);

    my $checksum = exists($checksums{$file})? $checksums{$file}: [];
    ok(exists $checksums{$file});
    my ($cs_type, $cs_value) = @{$checksum};

    if (!exists $checksums{$file}) {
        foreach ('chronological', 'unchanged') {
            skip('checksum not known', 0);
        }
        next;
    }

    my $old_checksum = '';
    my $chronological = 1;
    if (
        !exists $known_versions{$file} or
        !exists $known_versions{$file}->{$version} or
        !exists $known_versions{$file}->{$version}->{$cs_type}
    ) {
        if ($sane && exists $known_versions{$file}) {
            my $mov = -1;
            foreach my $ov (keys %{$known_versions{$file}}) {
                if ($mov < $ov) {
                    $mov = $ov;
                }
            }
            if ($version <= $mov) {
                print "# $module $version <= latest known version $mov\n";
                $chronological = 0;
            }
        }
        if ($chronological) {
            print
                "# new version:\n",
                "# $version  @{$checksum}  $file\n",
                "# consider adding this to $known_versions_file\n";
        }
        elsif (!exists $known_versions{$file}->{$version}->{$cs_type}) {
            # version is known, but checksum type is not
            print
                "# new checksum type:\n",
                "# $version  @{$checksum}  $file\n",
                "# consider adding this to $known_versions_file\n";
        }
    }
    else {
        $old_checksum = $known_versions{$file}->{$version}->{$cs_type};
    }
    ok($chronological);

    if ($old_checksum && $old_checksum ne $cs_value) {
        print
            "# $file has been changed without version update --\n",
            "# please increase ", '$', "$module", "::VERSION\n";
    }
    ok(!$old_checksum || $old_checksum eq $cs_value);
}

__END__
