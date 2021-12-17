#!perl

# Check that our perl modules compile without error.
# Shamelessly adapted from Lab::Measurement

use 5.010;
use strict;
use warnings;
use File::Find;
use Module::Load;
use Test::More;
use File::Spec::Functions 'abs2rel';

# Create file list

my @files;

sub installed {
    my $module = shift;
    eval {
        autoload $module;
        1;
    } or return;

    return 1;
}

File::Find::find(
    {
        wanted => sub { -f $_ && /\.pm$/ and push @files, $_ },
        no_chdir => 1
    },
    'lib'
);

@files = map { abs2rel( $_, 'lib' ) } @files;

# Do not keep backslashes in filenames, as they confuse require:
# perl uses slashes in %INC for modules which are 'used'.
# With backslashes the same module could be loaded twice.

@files = map {s(\\)(/)gr} @files;

plan tests => scalar @files;

for my $file (@files) {
    diag("trying to load $file ...");
    is( require $file, 1, "load $file" );
}

