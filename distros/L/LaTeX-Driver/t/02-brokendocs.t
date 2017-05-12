#!/usr/bin/perl
# $Id: 02-brokendocs.t 62 2007-10-03 14:20:44Z andrew $

use strict;
use blib;
use FindBin qw($Bin);
use File::Spec;
use lib ("$Bin/../lib", "$Bin/lib");
use Data::Dumper;

use Test::More;

BEGIN {
    eval "use Test::Exception";
    plan skip_all => "Test::Exception needed" if $@;
}

use Test::LaTeX::Driver;
use LaTeX::Driver;

plan tests => 8;

tidy_directory($basedir, $docname, $debug);

my $drv = LaTeX::Driver->new( source      => $docpath,
			      format      => 'dvi',
			      DEBUG       => $debug,
			      DEBUGPREFIX => '# [latex]: ' );

diag("Checking the formatting of a simple LaTeX document");
isa_ok($drv, 'LaTeX::Driver');
#is($drv->basedir, $basedir, "checking basedir");
is($drv->basename, $docname, "checking basename");
#is($drv->basepath, File::Spec->catpath('', $basedir, $docname), "checking basepath");
is($drv->formatter, 'latex', "formatter");

throws_ok( sub { $drv->run }, 'LaTeX::Driver::Exception', "formatting broken document $docname");

is($drv->stats->{runs}{latex},         1, "should have run latex once");
is($drv->stats->{runs}{bibtex},    undef, "should not have run bibtex");
is($drv->stats->{runs}{makeindex}, undef, "should not have run makeindex");


test_dvifile($drv, [ 'This is a test document with a broken LaTeX command.' ] );

tidy_directory($basedir, $docname, $debug)
    unless $no_cleanup;

exit(0);
