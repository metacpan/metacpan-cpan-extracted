#!/usr/bin/env perl

# Run Perl::Critic on non-Moose part of Lab::*

use 5.010;
use warnings;
use strict;
use Test::More;
use Test::Perl::Critic;
use File::Find;
use File::Spec::Functions 'catfile';

my @files;

find(
    {
        wanted => sub {
            my $file = $_;
            if ( $file =~ /\.(pm|pl|t)$/ ) {
                push @files, $file;
                return;
            }
        },
        no_chdir => 1,
    },
    catfile(qw/lib Lab Moose/)
);

for my $file (@files) {
    critic_ok($file);
}

done_testing();
