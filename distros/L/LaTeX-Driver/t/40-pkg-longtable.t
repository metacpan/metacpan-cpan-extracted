#!/usr/bin/perl
# $Id: 20-complexdoc.t 62 2007-10-03 14:20:44Z andrew $

# TODO: 1. test the output document content
#       2.  Skip tests when longtable not installed

use strict;
use blib;
use FindBin qw($Bin);
use File::Spec;
use lib ("$Bin/../lib", "$Bin/lib");
use Data::Dumper;

use Test::More tests => 9;

use Test::LaTeX::Driver;
use LaTeX::Driver;

tidy_directory($basedir, $docname, $debug);

my $drv = LaTeX::Driver->new( source    => $docpath,
			      format    => 'dvi',
			      TEXINPUTS => [ "$Bin/testdata/00-common"],
			      @DEBUGOPTS );


diag("Checking the formatting of a LaTeX document that uses 'longtable'");
isa_ok($drv, 'LaTeX::Driver');
#is($drv->basedir, $basedir, "checking basedir");
is($drv->basename, $docname, "checking basename");
#is($drv->basepath, File::Spec->catpath('', $basedir, $docname), "checking basepath");
is($drv->formatter, 'latex', "formatter");

ok($drv->run, "formatting $docname");

is($drv->stats->{pages}, 3, "should have 3 pages of output");
cmp_ok($drv->stats->{runs}{latex}, '>=',  2, "should have run latex at least two times");
cmp_ok($drv->stats->{runs}{latex}, '<=',  4, "should have run latex not more than four times");
ok(!$drv->stats->{runs}{bibtex},    "should not have run bibtex");
ok(!$drv->stats->{runs}{makeindex}, "should not have run makeindex");


if (0) {
test_dvifile($drv, [ "Complex Test Document $testno",	# title
		     'A.N. Other',			# author
		     '20 September 2007',		# date
		     '^Contents$',			# table of contents header
		     'This is a test document with all features.',
		     'The document has 12 pages.',
		     'Forward Reference',		# section title
		     'Here is a reference to page 9.',
		     'File Inclusion',
		     'Here we include another file.',
		     'Included File',			# section title
		     'This is text from an included file.',
		     'Bibliographic Citations',
		     'We reference the Badger book\\[',
		     '^WCC03$',
		     '\\] and the Camel book\\[',
		     '^Wal03$',
		     'Index Term',
		     'Here is the definition of the index term .xyzzy.',
	             '^References$',			# bibliography section heading
		     '^\\s*\\[WCC03\\]$',		# the bibiographic key
		     'Andy Wardley, Darren Chamberlain, and Dave Cross.',
	             '^Index$',				# Index section heading
		     '\\bxyzzy, 8$',			# the index term
		     '\\bxyzzy2, 12$',			# index term from the colophon
		     '11$',			        # page number 11
		     'Colophon$' ] );
}
tidy_directory($basedir, $docname, $debug)
    unless $no_cleanup;

exit(0);
