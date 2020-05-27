#!/usr/bin/perl
# Script to test LaTeX::Driver's error handling
# $Id: 01-errors.t 50 2007-09-28 10:51:47Z andrew $

use strict;
use blib;
use vars qw($testno $basedir $docname $drv $debug $debugprefix $dont_tidy_up);

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

plan tests => 5;


# For some of our tests we need a directory that does not exist, we
# had better make sure that someone hasn't created it.

my $nonexistent_dir = "$basedir/this-directory-should-not-exist";
die "hey, someone created our non-existent directory" if -d $nonexistent_dir;


diag("testing constructor error handling");

dies_ok { LaTeX::Driver->new( DEBUG       => $debug,
                              DEBUGPREFIX => $debugprefix ) } 'no source specified';
like($@, qr{no source specified}, 'constructor fails without a source');

dies_ok { LaTeX::Driver->new( source      => $docpath,
                              format      => 'tiff',
                              DEBUG       => $debug,
                              DEBUGPREFIX => $debugprefix ) } 'unsupported output type';
like($@, qr{invalid output format}, "'tiff' is not a supported output type");


diag("execution error handling");

$LaTeX::Driver::program_path{'xelatex'} = 'abcdefghijklmnopqrstuvwxyz0123456789';
my $drv = LaTeX::Driver->new( source => 't/testdata/01-errors/01-errors' );
dies_ok { $drv->run_latex; } 'Failure to start abcdefghijklm';


exit(0);

