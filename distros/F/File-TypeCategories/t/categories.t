#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings qw/warning had_no_warnings/;
use File::TypeCategories;

$ENV{HOME} = 'config';
files_ok();
files_possible();
files_nok();
files_exclude();
files_include();
files_perl();
types_match();
done_testing();

sub files_ok {
    my $files = File::TypeCategories->new();
    my @ok_files = qw{
        /blah/file
        /blah/file~other
        /blah/logo
        /blah/test.t
    };

    for my $file (@ok_files) {
        ok($files->file_ok($file), $file);
    }

    return;
}

sub files_possible {
    my $files = File::TypeCategories->new(
        include_type  => [qw/possible_a possible_b possible_c perl/],
        exclude_type  => [qw/possible_d possible_e possible_f php/],
        type_suffixes => {
            possible_a => { possible => ['a'], },
            possible_b => { possible => ['b'], },
            possible_c => { possible => ['c'], },
            possible_d => { possible => ['d'], },
            possible_e => { possible => ['e'], },
            possible_f => { possible => ['f'], },
        },
    );

    ok  $files->file_ok('abc'), 'abc is possible';
    ok !$files->file_ok('def'), 'def is possibly not';

    return;
}

sub files_nok {
    my $files = File::TypeCategories->new();
    my @nok_files = qw{
        /blah/CVS/thing
        /blah/file.copy
        /blah/file~
        /blah/.git
        /blah/logs
    };

    for my $file (@nok_files) {
        ok(!$files->file_ok($file), $file);
    }

    return;
}

sub files_exclude {
    my $files = File::TypeCategories->new( exclude => [qw{/test/}] );

    ok($files->file_ok("perl/test"), 'test exclude - not excluded');
    ok(!$files->file_ok("perl/test/"), 'test exclude - excluded');

    return;
}

sub files_include {
    my $files = File::TypeCategories->new( include => [qw{/test/}] );

    ok(!$files->file_ok("perl/test"), 'test exclude file - excluded');
    ok(!$files->file_ok("perl/test/"), 'test exlude dir - not excluded');

    return;
}

sub files_perl {
    my $files = File::TypeCategories->new( include_type => [qw{perl}] );

    ok($files->file_ok("bin/tfind"), 'perl include - not excluded');

    $files = File::TypeCategories->new( exclude_type => [qw{perl}] );

    ok(!$files->file_ok("bin/tfind"), 'perl include - excluded');

    return;
}

sub types_match {
    my $files = File::TypeCategories->new(
        include_type  => [qw{perl}],
        type_suffixes => {
            not_dot => {
                none => 1,
            },
        },
    );

    is(warning { $files->types_match('tfind', 'bad type') }, "No type 'bad type'\n", 'Missing type warned');
    $files->types_match('tfind', 'bad type');
    had_no_warnings('Second call doesn\'t warn');

    ok  $files->types_match('test.t'         , 'perl'), 'test.t          perl test';
    ok !$files->types_match('t/.does.nothing', 'perl'), 't/.does.nothing not perl';
    ok !$files->types_match('t/perlcriticrc' , 'perl'), 't/perlcriticrc  not perl';
    ok !$files->types_match('t/missing-file' , 'perl'), 't/missing-file  not perl';
    ok !$files->types_match('t'              , 'perl'), 't/              not perl';
    ok  $files->types_match('bin/tfind'      , 'perl'), 'bin/tfind       is perl';

    ok  $files->types_match('t/missing-file', 'not_dot'), 't/missing-file is not dot';
    ok !$files->types_match('t/f.ile'       , 'not_dot'), 't/f.ile        is dot';

    return;
}
