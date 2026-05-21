#!perl

# Copyright (C) 2025-2026 Rob Brown (bbb@cpan.org)
# SPEC file generator.

use strict;
use File::Temp;

# Create empty spec if doesn't exist:
my $spec = $0 =~ /([^\/]+)\.PL$/ ? $1 : die "$0: Bad program";
if (!-f $spec) { open my $fh, ">>", $spec; }

# Rebuild using cpan2pm if available:
0 == system "which cpan2rpm >/dev/null 2>/dev/null" and `rpm --eval %_rpmdir` =~ m{^(.+)} and !-d $1 and 0 == system "cpan2rpm --mk-rpm-dirs=~/rpm";

my @make_install_cmd = (
    'mkdir -v -p $RPM_BUILD_ROOT/usr/local/bin',
    'ln -s -v ../../bin/git-client $RPM_BUILD_ROOT/usr/local/bin/git',
    'make install',
);

my @cmd = (
    "cpan2rpm",
    "--spec-only",
    "--spec", $spec,
    "--make-maker","INSTALLDIRS=vendor",
    "--define", "makeinstall ".join(" ; ",@make_install_cmd),
    "."
    );

exec(@cmd);
warn "cpan2rpm: Broken [@cmd]\n";
warn "$spec: Creating emergency spec file ...\n";
exec "touch", $spec;
