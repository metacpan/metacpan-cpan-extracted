#!/usr/bin/env perl

###################################################################
#### NOTE env-var TEMP_DIRS_KEEP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

use lib 'blib/lib';

#use utf8;

our $VERSION = '1.0';

use Test::More;
use Test::More::UTF8;
use Mojo::Log;
use FindBin;
use File::Temp 'tempdir';
use File::Compare;

use Data::Roundtrip qw/perl2dump json2perl jsonfile2perl no-unicode-escape-permanently/;

use LaTeX::Easy::Templates;

my $VERBOSITY = 1;

my $log = Mojo::Log->new;

my $curdir = $FindBin::Bin;
# use this for keeping all tempfiles while CLEANUP=>1
# which is needed for deleting them all at the end
$File::Temp::KEEP_ALL = 1;
# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = File::Temp::tempdir(CLEANUP=>1); # will not be erased if env var is set
ok(-d $tmpdir, "tmpdir exists $tmpdir") or BAIL_OUT;

my $latte = LaTeX::Easy::Templates->new({
      'processors' => {
        'in-memory' => {
           'latex' => {
              'filename' => undef # create tmp
           },
           'template' => {
              # the template is in-memory string
              'content' => '...'
           },
           'output' => {
              'filename' => 'out.pdf'
           }
        },
        'on-disk' => {
          'latex' => {
              'filename' => undef, # create tmp
           },
           'template' => {
              'filepath' => File::Spec->catfile('t', 'templates', 'simple01', 'main.tex.tx'),
           },
           'output' => {
              'filename' => 'out2.pdf'
           }
        }
      }, # end processors
      'logfile' => File::Spec->catfile($tmpdir, 'xyz', 'abc.log'),
      'latex' => {
        'latex-driver-parameters' => {
           'format' => 'pdf(pdflatex)',
           'paths' => {
              #'pdflatex' => '/usr/local/xyz/pdflatex'
           }
        }
      },
      'verbosity' => 1,
      'cleanup' => 0,
});
ok(defined $latte, 'LaTeX::Easy::Templates->new()'." : called and got good result.") or BAIL_OUT;

# if you set env var TEMP_DIRS_KEEP=1 when running
# the temp files WILL NOT BE DELETED otherwise
# they are deleted automatically, unless some other module
# messes up with $File::Temp::KEEP_ALL
diag "temp dir: $tmpdir ...";
do {
	$File::Temp::KEEP_ALL = 0;
	File::Temp::cleanup;
	diag "temp files cleaned!";
} unless exists($ENV{'TEMP_DIRS_KEEP'}) && $ENV{'TEMP_DIRS_KEEP'}>0;

# END
done_testing()
