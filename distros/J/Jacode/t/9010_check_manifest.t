######################################################################
#
# t/9010_check_manifest.t - verify MANIFEST lists all expected files
#
# Copyright (c) 2026 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }
use warnings;
use FindBin;

my $dist_root = "$FindBin::Bin/..";
my $manifest  = "$dist_root/MANIFEST";

# Read MANIFEST
open(MF, $manifest) or die "Cannot open MANIFEST: $!\n";
my @listed = grep { /\S/ && !/^#/ } map { chomp; $_ } <MF>;
close(MF);

# Files that must always be present in a Jacode distribution
my @required = qw(
    lib/Jacode.pm
    lib/jacode.pl
    Changes
    MANIFEST
    README
    LICENSE
    CONTRIBUTING
    SECURITY.md
    Makefile.PL
    META.yml
    META.json
    README2ND
    pmake.bat
    t/9010_check_manifest.t
);

my %listed_set = map { $_ => 1 } @listed;

print "1..", scalar(@required) + 1, "\n";
my $tno = 1;

# Test 1: MANIFEST file itself is readable
if (-f $manifest) {
    print "ok $tno - MANIFEST is readable\n";
} else {
    print "not ok $tno - MANIFEST is readable\n";
}
$tno++;

# Tests: each required file is listed and exists on disk
for my $file (@required) {
    my $listed  = $listed_set{$file} ? 1 : 0;
    my $exists  = -f "$dist_root/$file" ? 1 : 0;
    if ($listed && $exists) {
        print "ok $tno - $file listed in MANIFEST and exists on disk\n";
    } elsif (!$listed) {
        print "not ok $tno - $file not listed in MANIFEST\n";
    } else {
        print "not ok $tno - $file listed in MANIFEST but missing on disk\n";
    }
    $tno++;
}

__END__
