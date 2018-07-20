#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2018 Joelle Maslak
# All Rights Reserved - See License
#

#
# Object Attribute Tests (this is a work in progress of seperating these
# out from 01-Basic.t)
#

use strict;
use warnings;
use autodie;

use v5.10;

use Carp;

use Test2::V0;

use File::ByLine;

subtest file_attribute => sub {
    my $byline = File::ByLine->new();
    ok( defined($byline), "Object created" );

    is( $byline->file(), undef, "File defaults to empty" );

    my @tests = (
        {
            test => 'Single file',
            list => ['file.txt'],
        },
        {
            test => 'Two files',
            list => [ 'file.txt', 'file2.txt' ],
        },
    );

    foreach my $test (@tests) {
        my $desc = $test->{test};
        my $list = $test->{list};

        if ( scalar(@$list) == 1 ) {
            is( $byline->file( $list->[0] ), $list->[0], "$desc - No List" );
            is( $byline->file($list),        $list,      "$desc - In List" );
        } else {
            is( $byline->file(@$list), $list, "$desc - List of Elements" );
            is( $byline->file($list),  $list, "$desc - Arrayref of Elements" );
        }
    }

    ok( dies { $byline->file(undef) }, "file() does not accept undef" );
};

subtest processes_attribute => sub {
    my $byline = File::ByLine->new();
    ok( defined($byline), "Object created" );

    is( $byline->processes(), 1, "processes defaults to 1" );
    is( $byline->p(),         1, "processes p alias defaults to 1" );

    ok( dies { $byline->processes(undef) }, "processes() does not accept undef" );
    ok( dies { $byline->processes(0) },     "processes() does not accept 0" );
    ok( dies { $byline->processes( 1, 2 ) }, "processes() does not accept list" );
    ok( dies { $byline->processes( [1] ) }, "processes() does not accept arrayref" );

    is( $byline->p(1),        1, "processes p alias set to 1" );
    is( $byline->p(),         1, "processes p alias is 1" );
};

subtest extended_info => sub {
    my $byline = File::ByLine->new();
    ok( defined($byline), "Object created" );

    ok( !$byline->extended_info(), "extended_info defaults to false" );

    ok( $byline->extended_info(1),      "extended_info set to true" );
    ok( $byline->extended_info(),       "extended_info contains true" );
    ok( $byline->ei(),                  "extended_info ei alias contains true" );
    ok( !$byline->extended_info(undef), "extended_info set to false" );
    ok( !$byline->extended_info(),      "extended_info contains false" );
    ok( !$byline->ei(),                 "extended_info ei alias contains false" );
    ok( $byline->ei(1),                 "extended_info ei alias set to true" );
    ok( $byline->extended_info(),       "extended_info contains true" );
    ok( $byline->ei(),                  "extended_info ei alias contains true" );
};

subtest file_attribute => sub {
    my $byline = File::ByLine->new();
    ok( defined($byline), "Object created" );

    is( $byline->file(),          undef,     "file not defined" );
    is( $byline->f(),             undef,     "file f alias not defined" );
    is( $byline->file('abc.txt'), 'abc.txt', "file set to abc.txt" );
    is( $byline->file(),          'abc.txt', "file is abc.txt" );
    is( $byline->f(),             'abc.txt', "file f alias is abc.txt" );
    is( $byline->f('def.txt'),    'def.txt', "file f alias set to def.txt" );
    is( $byline->file(),          'def.txt', "file is def.txt" );
    is( $byline->f(),             'def.txt', "file f alias is def.txt" );
};

subtest header_all_files => sub {
    my $byline = File::ByLine->new();
    ok( defined($byline), "Object created" );

    ok( !$byline->header_all_files(), "header_all_files defaults to false" );
    ok( !$byline->haf(),              "header_all_files haf alias defaultls to false" );

    ok( $byline->header_all_files(1),      "header_all_files set to true" );
    ok( $byline->header_all_files(),       "header_all_files contains true" );
    ok( $byline->haf(),                    "header_all_files haf alias contains true" );
    ok( !$byline->header_all_files(undef), "header_all_files set to false" );
    ok( !$byline->header_all_files(),      "header_all_files contains false" );
    ok( !$byline->haf(),                   "header_all_files haf alias contains false" );
    ok( $byline->haf(1),                   "header_all_files haf alias set to true" );
    ok( $byline->header_all_files(),       "header_all_files contains true" );
    ok( $byline->haf(),                    "header_all_files haf alias contains true" );
};

subtest header_handler => sub {
    my $byline = File::ByLine->new();
    ok( defined($byline), "Object created" );

    my $ret;
    my $sub = sub { return $ret; };

    is( $byline->header_handler(), undef, "header_handler defaults to undef" );
    is( $byline->hh(),             undef, "header_handler hh alias defaults to undef" );

    ok( $byline->header_handler($sub), "header_handler set" );
    $ret = 1;
    $byline->header_handler()->();
    is( $ret, 1, "header_handler executes" );
    $ret = 2;
    $byline->hh()->();
    is( $ret, 2, "header_handler hh alias executes" );

    ok( !$byline->hh(undef), "header_handler set to undef" );
    is( $byline->header_handler(), undef, "header_handler is undef" );
    is( $byline->hh(),             undef, "header_handler hh alias is undef" );
};

subtest header_skip => sub {
    my $byline = File::ByLine->new();
    ok( defined($byline), "Object created" );

    is( $byline->header_skip(), undef, "header_skip defaults to undef" );
    is( $byline->hs(),          undef, "header_skip hs alias defaults to undef" );

    is( $byline->header_skip(1), 1,     "header_skip set to 1" );
    is( $byline->header_skip(),  1,     "header_skip is 1" );
    is( $byline->hs(),           1,     "header_skip hs alias is 1" );
    is( $byline->hs(undef),      undef, "header_skip hs alias set to undef" );
    is( $byline->header_skip(),  undef, "header_skip is undef" );
    is( $byline->hs(),           undef, "header_skip hs alias is undef" );
};

subtest skip_unreadable => sub {
    my $byline = File::ByLine->new();
    ok( defined($byline), "Object created" );

    ok( !$byline->skip_unreadable(), "skip_unreadable defaults to false" );
    ok( !$byline->su(),              "skip_unreadable su alias defaults to false" );

    ok( $byline->skip_unreadable(1),      "skip_unreadable set to true" );
    ok( $byline->skip_unreadable(),       "skip_unreadable contains true" );
    ok( $byline->su(),                    "skip_unreadable su alias contains to false" );
    ok( !$byline->skip_unreadable(undef), "skip_unreadable set to false" );
    ok( !$byline->skip_unreadable(),      "skip_unreadable contains false" );
    ok( !$byline->su(),                   "skip_unreadable su alias contains false" );
    ok( $byline->su(1),                   "skip_unreadable su alias set to true" );
    ok( $byline->skip_unreadable(),       "skip_unreadable contains true" );
    ok( $byline->su(),                    "skip_unreadable su alias contains to false" );
};

done_testing();

