#!/usr/bin/perl -w

#
# Copyright (C) 2007-2008 Alex Linke <alinke@lingua-systems.com>
# Copyright (C) 2009-2016 Lingua-Systems Software GmbH
# Copyright (C) 2016-2017 Netzum Sorglos, Lingua-Systems Software GmbH
# Copyright (C) 2017-2022 Netzum Sorglos Software GmbH
#

use strict;
use IO::File;

my $tbl_file = 'xml/tables.dump';
my $infile = $ARGV[0] || die "usage: $0 file";

my $fh = new IO::File();

local $/;

# read input file
$fh->open($infile) or die "$infile: $!\n";
my $in_content = <$fh>;
$fh->close();

# read tables file
$fh->open($tbl_file) or die "$tbl_file: $!\n";
my $tbls = <$fh>;
$fh->close();

if ( $in_content =~ s/\n\%tables;\s+# PLACEHOLDER\s*\n/\n$tbls\n/ ) {
    print "$infile: substituted tables: " . length($tbls) . " bytes.\n";
}
else {
    print "$infile: no substitution.\n";
    exit 1;
}

chmod 0644, $infile or die "chmod: $!\n";

# write output to input file
$fh->open("> $infile") or die "$infile: $!\n";
print $fh $in_content;
$fh->close();

# vim: set ft=perl sts=4 sw=4 ts=4 ai et:
