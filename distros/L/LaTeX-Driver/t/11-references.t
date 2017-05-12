#!/usr/bin/perl
# $Id: 11-references.t 62 2007-10-03 14:20:44Z andrew $

use strict;
use blib;
use FindBin qw($Bin);
use File::Spec;
use lib ("$Bin/../lib", "$Bin/lib");
use Data::Dumper;

use Test::More tests => 8;

use Test::LaTeX::Driver;
use LaTeX::Driver;

tidy_directory($basedir, $docname, $debug);

my $drv = LaTeX::Driver->new( source => $docpath,
			      format => 'dvi',
			      @DEBUGOPTS );

diag("Checking the formatting of a LaTeX document with forward references");
isa_ok($drv, 'LaTeX::Driver');
#is($drv->basedir, $basedir, "checking basedir");
is($drv->basename, $docname, "checking basename");
#is($drv->basepath, File::Spec->catpath('', $basedir, $docname), "checking basepath");
is($drv->formatter, 'latex', "formatter");

ok($drv->run, "formatting $docname");

is($drv->stats->{runs}{latex},         2, "should have run latex twice");
is($drv->stats->{runs}{bibtex},    undef, "should not have run bibtex");
is($drv->stats->{runs}{makeindex}, undef, "should not have run makeindex");

test_dvifile($drv, [ "Simple Test Document $testno",	# title
		     'A.N. Other',			# author
		     '20 September 2007',		# date
		     'This is a test document containing a forward reference.',
	             'See page 2.',			# second para with page ref
		     '^ 1$',				# page number 1
	             'This is the second page.',	# text on second page
		     '^ 2$' ] );			# page number 2

tidy_directory($basedir, $docname, $debug)
    unless $no_cleanup;

exit(0);
