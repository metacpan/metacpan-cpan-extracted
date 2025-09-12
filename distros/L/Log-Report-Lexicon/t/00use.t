#!/usr/bin/env perl
use warnings;
use strict;

use Test::More;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/PPI
    POSIX
    Test::Pod
    Log::Report::Optional
    Log::Report
    String::Print
   /;

warn "Perl $]\n";
foreach my $package (sort @show_versions)
{   eval "require $package";

    my $report
      = !$@                    ? "version ". ($package->VERSION || 'unknown')
      : $@ =~ m/^Can't locate/ ? "not installed"
      : "reports error";

    warn "$package $report\n";
}

use_ok('Log::Report');
use_ok('Log::Report::Extract');
use_ok('Log::Report::Lexicon::Index');
use_ok('Log::Report::Lexicon::PO');
use_ok('Log::Report::Lexicon::POT');
use_ok('Log::Report::Lexicon::POTcompact');
use_ok('Log::Report::Translator::Context');
use_ok('Log::Report::Translator');
use_ok('Log::Report::Translator::POT');

# Log::Report::Extract::PerlPPI         requires optional PPI

done_testing;
