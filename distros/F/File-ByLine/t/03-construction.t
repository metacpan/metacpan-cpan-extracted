#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2018 Joelle Maslak
# All Rights Reserved - See License
#

#
# Object Construction Tests
#

use strict;
use warnings;
use autodie;

use v5.10;

use Carp;

use Test2::V0;

use File::ByLine;

subtest no_params => sub {
    my $byline = File::ByLine->new();
    ok( defined($byline), "Object created" );

    is( $byline->file(),           undef, "File defaults to empty" );
    is( $byline->header_handler(), undef, "No header handler by default" );
    is( $byline->processes,        1,     "Processes defaults to 1" );
    ok( !$byline->extended_info(),    "Extended info not used by default" );
    ok( !$byline->header_skip(),      "Header does not skip by default" );
    ok( !$byline->header_all_files(), "Header not processed for all files by default" );
    ok( !$byline->skip_unreadable(),  "Skip unreadable files not set by default" );
};

subtest with_params_hash => sub {
    my $byline = File::ByLine->new(
        {
            file             => 'foo.txt',
            extended_info    => 1,
            header_all_files => 1,
            header_handler   => undef,
            header_skip      => 1,
            processes        => 1,
            skip_unreadable  => 1
        }
    );
    ok( defined($byline), "Object created" );

    is( $byline->file(),           'foo.txt', "File set" );
    is( $byline->header_handler(), undef,     "No header handler by default" );
    is( $byline->processes,        1,         "Processes set to 1" );
    ok( $byline->extended_info(),    "Extended info set" );
    ok( $byline->header_all_files(), "Header processed for all files" );
    ok( $byline->header_skip(),      "Header skip set" );
    ok( $byline->skip_unreadable(),  "Skip unreadable set" );
};

subtest with_param_abbrev_hash => sub {
    my $byline = File::ByLine->new(
        {
            f   => 'foo.txt',
            ei  => 1,
            haf => 1,
            hh  => undef,
            hs  => 1,
            p   => 1,
            su  => 1
        }
    );
    ok( defined($byline), "Object created" );

    is( $byline->file(),           'foo.txt', "File set" );
    is( $byline->header_handler(), undef,     "No header handler by default" );
    is( $byline->processes,        1,         "Processes set to 1" );
    ok( $byline->extended_info(),    "Extended info set" );
    ok( $byline->header_all_files(), "Header processed for all files" );
    ok( $byline->header_skip(),      "Header skip set" );
    ok( $byline->skip_unreadable(),  "Skip unreadable set" );
};

subtest with_params_list => sub {
    my $byline = File::ByLine->new(
        file             => 'foo.txt',
        extended_info    => 1,
        header_all_files => 1,
        header_skip      => 1,
        processes        => 1,
        skip_unreadable  => 1
    );
    ok( defined($byline), "Object created" );

    is( $byline->file(),           'foo.txt', "File set" );
    is( $byline->header_handler(), undef,     "No header handler by default" );
    is( $byline->processes,        1,         "Processes set to 1" );
    ok( $byline->extended_info(),    "Extended info set" );
    ok( $byline->header_all_files(), "Header processed for all files" );
    ok( $byline->header_skip(),      "Header skip set" );
    ok( $byline->skip_unreadable(),  "Skip unreadable set" );
};

subtest invalid_param => sub {
    ok dies { File::ByLine->new( foo => 'bar' ) }, "Dies with invalid parameter, list form";
    ok dies { File::ByLine->new( { foo => 'bar' } ) }, "Dies with invalid parameter, hash form";
    ok dies { File::ByLine->new( processes => 1, 'foo' ) },
      "Dies with invalid number of parameters";
};

done_testing();

