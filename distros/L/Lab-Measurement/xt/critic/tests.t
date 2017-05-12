#!/usr/bin/env perl

# Run Perl::Critic on t and xt dirs.
use 5.010;
use warnings;
use strict;
use Test::More;
use Test::Perl::Critic;
use File::Find;
use File::Spec::Functions qw/catfile/;

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
    't',
    catfile( 'xt', 'critic' )
);

push @files, catfile(qw/xt perltidy.pl/), catfile(qw/xt pre-commit.pl/);

for my $file (@files) {
    critic_ok($file);
}

done_testing();
