#! /usr/bin/perl -w
use lib '../lib';
use strict;
use Test::More tests => 2;

# test if the xgettext '-f' parameter stripts newlines from the filenames
# http://bugs.debian.org/307777

use_ok('Locale::Maketext::Extract::Run');

my $inputfile = "$$.in";
my $listfile  = "$$.list";
my $outfile   = "$$.out";

open(F, ">$inputfile") or die("create $inputfile failed: $!");
print F "loc('test')";
close F;

open(F, ">$listfile") or die("create $inputfile failed: $!");
print F "$inputfile\n/dev/null";
close F;

Locale::Maketext::Extract::Run::xgettext('-f', $listfile, '-o', $outfile);

ok(-s $outfile, "non-empty output for Locale::Maketext::Extract::Run::xgettext");

unlink $_ for ($inputfile, $listfile, $outfile);


