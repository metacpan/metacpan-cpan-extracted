#!/usr/bin/perl
# $Id: 15-bibtex.t 62 2007-10-03 14:20:44Z andrew $

use strict;
use blib;
use FindBin qw($Bin);
use File::Spec;
use lib ("$Bin/../lib", "$Bin/lib");
use Data::Dumper;

use Test::More;

use Test::LaTeX::Driver;
use LaTeX::Driver;

plan skip_all => 'BIBTEX_TESTS not set.  Requires lastpage.sty.' 
      unless $ENV{BIBTEX_TESTS};
plan tests => 8;

tidy_directory($basedir, $docname, $debug);

my $drv = LaTeX::Driver->new( source => $docpath,
			      format => 'dvi',
			      @DEBUGOPTS );

diag("Checking the formatting of a LaTeX document with a bibliography");
isa_ok($drv, 'LaTeX::Driver');
#is($drv->basedir, $basedir, "checking basedir");
is($drv->basename, $docname, "checking basename");
#is($drv->basepath, File::Spec->catpath('', $basedir, $docname), "checking basepath");
is($drv->formatter, 'latex', "formatter");

ok($drv->run, "formatting $docname");

is($drv->stats->{runs}{latex},         3, "should have run latex three times");
is($drv->stats->{runs}{bibtex},        1, "should have run bibtex once");
is($drv->stats->{runs}{makeindex}, undef, "should not have run makeindex");

test_dvifile($drv, [ "Simple Test Document $testno",	# title
		     'A.N. Other',			# author
		     '20 September 2007',		# date
		     'This is a test document with a bibliography.',
		     'We reference the Badger book\\[',
		     'WCC03',
	             '^References$',			# bibliography section heading
		     '^\\s*\\[WCC03\\]$',		# the bibiographic key
		     'Andy Wardley, Darren Chamberlain, and Dave Cross.',
		     '^ 1$' ] );			# page number 1

tidy_directory($basedir, $docname, $debug)
    unless $no_cleanup;

exit(0);
