#!perl

use 5.006;
use strict;
use warnings;

# this test was generated with
# Dist::Zilla::Plugin::Author::SKIRMESS::RepositoryBase 0.024

use File::Spec;

use Perl::Critic::Utils qw(all_perl_files);
use Test::More;
use Test::Perl::Critic;

my @dirs = qw(bin lib t xt);

my @ignores = ();
my %file;
@file{ all_perl_files(@dirs) } = ();
delete @file{@ignores};
my @files = keys %file;

if ( @files == 0 ) {
    BAIL_OUT('no files to criticize found');
}

all_critic_ok(@files);
