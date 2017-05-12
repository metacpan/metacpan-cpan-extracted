#!/usr/bin/perl
# $Id: 30-output-to-variable.t 62 2007-10-03 14:20:44Z andrew $

use strict;
use blib;
use FindBin qw($Bin);
use File::Spec;
use lib ("$Bin/../lib", "$Bin/lib");
use Data::Dumper;

use Test::More; 
use Test::LaTeX::Driver;
use LaTeX::Driver;

plan skip_all => 'dvips not installed' if system('dvips -v');
plan tests => 9;

tidy_directory($basedir, $docname, $debug);

my $output;
my $drv = LaTeX::Driver->new( source      => $docpath,
			      format      => 'ps',
			      output      => \$output,
			      @DEBUGOPTS );

diag("Checking the formatting of a simple LaTeX document into a variable");
isa_ok($drv, 'LaTeX::Driver');
#is($drv->basedir, $basedir, "checking basedir");
is($drv->basename, $docname, "checking basename");
#is($drv->basepath, File::Spec->catpath('', $basedir, $docname), "checking basepath");
is($drv->formatter, 'latex', "formatter");

ok($drv->run, "formatting $docname");

is($drv->stats->{runs}{latex},         1, "should have run latex once");
is($drv->stats->{runs}{bibtex},    undef, "should not have run bibtex");
is($drv->stats->{runs}{makeindex}, undef, "should not have run makeindex");
is($drv->stats->{runs}{dvips},         1, "should have run dvips once");

like($output, qr/^%!PS/, "got postscript in output string");


tidy_directory($basedir, $docname, $debug)
 unless $no_cleanup;


exit(0);
