#!perl

# Copyright (C) 2025 Rob Brown (bbb@cpan.org)
# SPEC file generator.

use strict;
use File::Temp;

# Create empty spec if doesn't exist:
my $spec = $0 =~ /([^\/]+)\.PL$/ ? $1 : die "$0: Bad program";
if (!-f $spec) { open my $fh, ">>", $spec; }

# Rebuild using cpan2pm if available:
0 == system "which cpan2rpm >/dev/null 2>/dev/null" and `rpm --eval %_rpmdir` =~ m{^(.+)} and !-d $1 and 0 == system "cpan2rpm --mk-rpm-dirs=~/rpm";

my @cmd = (
    "cpan2rpm",
    "--force",
    "--spec-only",
    "--spec", $spec,
    "."
    );

exec(@cmd);
warn "cpan2rpm: Broken [@cmd]\n";
warn "$spec: Creating emergency spec file ...\n";
exec "touch", $spec;
