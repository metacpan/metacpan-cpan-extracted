#!/usr/bin/perl

use strict;
use warnings;

use File::Find;
use File::Basename;
use Test::More;

my $lib_path = dirname(__FILE__) . '/../lib';
my %LIST;
find(
    sub {
        if ( $File::Find::name =~
            m{ (lib [/] Hyper [/] [A-Za-z0-9_/-]+ [.]pm) $ }xms
        ) {
                $LIST{"../$1"} = 1;
            }
    },
    $lib_path,
);

plan ( tests => (scalar keys %LIST) );

for my $module (sort keys %LIST) {
    open( my $file, '<', "$lib_path/$module" ) or die "cannnot open file $module";
    local $/;
    my $text = <$file>;

        ok( (
            1
            && ( $text !~ m{[\x0D]}g )          # DOS line ending (CR)
            && ( $text !~ m{[\x09]}g )          # TAB
            && ( $text !~ m{[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\xFF]}g ) # shit
            && ( $text !~ m{[ ][\x0D\x0A]}g )   # trailing space
            ),
            "$module sane characters"
        );
}

