#!/usr/bin/perl
# $Id: 14-makeindex.t 62 2007-10-03 14:20:44Z andrew $
#
# Test out invocation of makeindex:
# * Tests the default invocation of makeindex
# * Tests alternate style (replaces comma after index term with colon)
# * Tests index options (uses -l for letter ordering of index entries
 

use strict;
use warnings;

use vars qw($debug $dont_tidy_up $drv);
use blib;
use FindBin qw($Bin);
use File::Spec;
use lib ("$Bin/../lib", "$Bin/lib");
use Data::Dumper;

use Test::More;

use Test::LaTeX::Driver;
use LaTeX::Driver;

system('makeindex', '--help');
if ($? == -1) {
  plan skip_all => q{Can't execute "makeindex"};
}
else {
  plan tests => 14;
}

tidy_directory($basedir, $docname, $debug);

$drv = LaTeX::Driver->new( source => $docpath,
			   format => 'dvi',
			   @DEBUGOPTS );

diag("Checking the formatting of a LaTeX document with an index");
isa_ok($drv, 'LaTeX::Driver');
#is($drv->basedir, $basedir, "checking basedir");
is($drv->basename, $docname, "checking basename");
#is($drv->basepath, File::Spec->catpath('', $basedir, $docname), "checking basepath");
is($drv->formatter, 'latex', "formatter");

ok($drv->run, "formatting $docname");

is($drv->stats->{runs}{latex},         2, "should have run latex twice");
is($drv->stats->{runs}{bibtex},    undef, "should not have run bibtex");
is($drv->stats->{runs}{makeindex},     1, "should have run makeindex once");

test_dvifile($drv, [ "Simple Test Document $testno",	# title
		     'A.N. Other',			# author
		     '20 September 2007',		# date
		     "This is a test document that defines the index terms `seal' and `sea lion'.",
		     "These are the example terms used in the makeindex man page.",
		     '^ 1$',				# page number 1
	             '^Index$',				# Index section heading
		     # word ordering of index entries
		     'sea lion, 1$',			# two-word index term
		     'seal, 1$',			# one-word index term
		     '^ 2$' ] );			# page number 2

tidy_directory($basedir, $docname, $debug);

diag("run again with an explicit index style option");
$drv = LaTeX::Driver->new( source     => $docpath,
			   format     => 'dvi',
			   indexstyle => 'testind',
			   @DEBUGOPTS );


isa_ok($drv, 'LaTeX::Driver');

ok($drv->run, "formatting $docname");

test_dvifile($drv, [ '^Index$',				# Index section heading
		     # word ordering of index entries
		     'sea lion: 1$',			# two-word index term
		     'seal: 1$',			# one-word index term
		     '^ 2$' ] );			# page number 2

tidy_directory($basedir, $docname, $debug);

diag("run again with -l (letter ordering) option");
$drv = LaTeX::Driver->new( source       => $docpath,
			   format       => 'dvi',
			   indexoptions => '-l',
			   @DEBUGOPTS );

isa_ok($drv, 'LaTeX::Driver');

ok($drv->run, "formatting $docname");

test_dvifile($drv, [ '^Index$',				# Index section heading
		     # letter ordering of index entries
		     'seal, 1$',			# one-word index term
		     'sea lion, 1$',			# two-word index term
		     '^ 2$' ] );			# page number 2

tidy_directory($basedir, $docname, $debug)
    unless $no_cleanup;

exit(0);
