#!perl

use 5.006;
use strict;
use warnings;

# this test was generated with
# Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::Perl::Critic 0.008

use File::Spec;

use Perl::Critic::Utils qw(all_perl_files);
use Test::More;
use Test::Perl::Critic;

my @dirs = qw(bin lib t xt);

my @ignores = ();

my %ignore = map { $_ => 1 } @ignores;

my @files = grep { !exists $ignore{$_} } all_perl_files(@dirs);

if ( @files == 0 ) {
    BAIL_OUT('no files to criticize found');
}

all_critic_ok(@files);
