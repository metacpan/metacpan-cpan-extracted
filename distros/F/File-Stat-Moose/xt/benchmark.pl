#!/usr/bin/perl

use lib 'lib', '../lib';







package main;

use Benchmark ':all';

my $result = timethese($ARGV[0] || -1, {
    '1_CoreStat' => sub {

        package My::CoreStat;
        my $size = (stat $0)[7];

    },
    '2_FileStat' => sub {

        package My::FileStat;
        use File::stat 'stat';
        my $st = stat $0;
        my $size = $st->size;

    },
    '3_FileStatMoose' => sub { 

        package My::FileStatMoose;
        use File::Stat::Moose ();
        my $size = File::Stat::Moose->new( file => $0 )->size;

    },
    '4_FileStatMooseFunc' => sub {

        package My::FileStatMooseFunc;
        use File::Stat::Moose 'stat';
        my $size = (stat $0)[7];

    },
    '4_FileStatMooseFuncStrictAccessors' => sub {

        package My::FileStatMooseStrictAccessors;
        use File::Stat::Moose ();
        my $size = File::Stat::Moose->new( file => $0, strict_accessors => 1 )->size;

    },
});

cmpthese($result);
