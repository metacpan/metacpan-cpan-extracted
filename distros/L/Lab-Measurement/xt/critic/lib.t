#!/usr/bin/env perl

# Run Perl::Critic on selected files in lib/Lab.

use 5.010;
use warnings;
use strict;
use Test::More;
use Test::Perl::Critic;
use File::Spec::Functions qw/catfile/;
use File::Find;

my @tests = map {qr/$_/i} qw/
    connection.*(log|mock)
    sr830.*aux
    /;

my @files;

find(
    {
        wanted => sub {
            my $file = $_;
            for my $test (@tests) {
                if ( $file !~ /\.(pm|pl|t)$/ ) {
                    return;
                }

                if ( $file =~ $test ) {
                    push @files, $file;
                    return;
                }
            }
        },
        no_chdir => 1,
    },
    'lib'
);

for my $file (@files) {
    critic_ok($file);
}

done_testing();
