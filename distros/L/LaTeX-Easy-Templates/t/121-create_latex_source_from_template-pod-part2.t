#!/usr/bin/env perl

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use strict;
use warnings;

use lib 'blib/lib';

#use utf8;

our $VERSION = '1.03';

use Test::More;
use Test::More::UTF8;
use Mojo::Log;
use FindBin;
use Test::TempDir::Tiny;
use File::Compare;

use Data::Roundtrip qw/perl2dump json2perl jsonfile2perl no-unicode-escape-permanently/;

use LaTeX::Easy::Templates;

my $VERBOSITY = 1;

my $log = Mojo::Log->new;

my $curdir = $FindBin::Bin;
# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
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

diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

# END
done_testing()
