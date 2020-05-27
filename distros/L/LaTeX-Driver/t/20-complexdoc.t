#!/usr/bin/perl
# $Id: 20-complexdoc.t 79 2009-01-19 13:42:09Z andrew $

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
plan tests => 10;

tidy_directory($basedir, $docname, $debug);

my $drv = LaTeX::Driver->new( source    => $docpath,
                              format    => 'dvi',
                              TEXINPUTS => [ "$Bin/testdata/00-common"],
                              @DEBUGOPTS );


diag("Checking the formatting of a complex LaTeX document with references, a bibliography, an index, etc");
isa_ok($drv, 'LaTeX::Driver');
#is($drv->basedir, $basedir, "checking basedir");
is($drv->basename, $docname, "checking basename");
#is($drv->basepath, File::Spec->catpath('', $basedir, $docname), "checking basepath");
is($drv->formatter, 'latex', "formatter");

ok($drv->run, "formatting $docname");

is($drv->stats->{pages}, 12, "should have 12 pages of output");
cmp_ok($drv->stats->{runs}{latex}, '>=',  5, "should have run latex at least five times");
cmp_ok($drv->stats->{runs}{latex}, '<=',  8, "should have run latex not more than eight times");
is($drv->stats->{runs}{bibtex},    1, "should have run bibtex once");
is($drv->stats->{runs}{makeindex}, 2, "should have run makeindex twice");


test_dvifile($drv, [ "Complex Test Document $testno",   # title
                     'A.N. Other',                      # author
                     '20 September 2007',               # date
                     '^Contents$',                      # table of contents header
                     'This is a test document with all features.',
                     'The document has 12 pages.',
                     'Forward Reference',               # section title
                     'Here is a reference to page 9.',
                     'File Inclusion',
                     'Here we include another file.',
                     'Included File',                   # section title
                     'This is text from an included file.',
                     'Bibliographic Citations',
                     'We reference the Badger book\\[',
                     '^WCC03$',
                     '\\] and the Camel book\\[',
                     '^Wal03$',
                     'Index Term',
                     'Here is the definition of the index term .xyzzy.',
                     '^References$',                    # bibliography section heading
                     '^\\s*\\[WCC03\\]$',               # the bibiographic key
                     'Andy Wardley, Darren Chamberlain, and Dave Cross.',
                     '^Index$',                         # Index section heading
                     '\\bxyzzy, 8$',                    # the index term
                     '\\bxyzzy2, 12$',                  # index term from the colophon
                     '11$',                             # page number 11
                     'Colophon$' ] );

tidy_directory($basedir, $docname, $debug)
    unless $no_cleanup;

exit(0);
