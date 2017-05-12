#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2006-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use IO::File;
use strict;
use Test;

BEGIN { plan tests => 6 }
BEGIN { require "./t/test_utils.pl"; }

delete $ENV{DIRPROJECT};  # Prevent failure if mis-pre-set by caller
test_setup_area();

chdir 'test_dir';
{
    my $out = `${PERL} ../project_bin --project_bin-help 2>&1`;
    ok($out =~ /DESCRIPTION/);
}
{
    my $out = `${PERL} '$ENV{DIRPROJECT_PREFIX}/bin/testprog' arguments`;
    # This will execute 30_project_bin.pl
    ok($out =~ m!hello world!);
}
{
    my $out = `${PERL} '$ENV{DIRPROJECT_PREFIX}/bin/testrun' arguments`;
    # This will execute 30_project_bin.pl via a scripted startup
    ok($out =~ m!hello world!);
}
{
    my $out = `${PERL} '$ENV{DIRPROJECT_PREFIX}/bin/project_which' testprog`;
    ok($out =~ m!checkout/bin/testprog!);
}
{
    my $out = `${PERL} '$ENV{DIRPROJECT_PREFIX}/bin/project_bin' --project_bin-which testprog`;
    ok($out =~ m!checkout/bin/testprog!);
}
{
    my $out = `${PERL} '$ENV{DIRPROJECT_PREFIX}/bin/testprog' --project_bin-which`;
    ok($out =~ m!checkout/bin/testprog!);
}
