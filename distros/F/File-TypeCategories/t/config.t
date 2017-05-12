#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings qw/warning had_no_warnings/;
use File::TypeCategories;

$ENV{HOME} = 'config';

test_config();
done_testing();

sub test_config {
    no warnings;
    my @data = (
        # ignore - only other types
        {
            name => 'editors',
            match => [qw{
                file~
                file~1
                .file.swp
                .file.swo
            }],
        },
        {
            name => 'vim',
            match => [qw{
                .file.swp
                .file.swo
                dir/.file.swp
                dir/.file.swo
            }],
        },
        {
            name => 'images',
            match => [qw{
                pic.png
                pic.jpg
                pic.jpeg
                pic.gif
                pic.swf
                pic.nef
                pic.tif
            }],
        },
        {
            name => 'fonts',
            match => [qw{
                font.ttf
                web-font.wof
            }],
        },
        {
            name => 'logs',
            match => [qw{
                error.log
                log/myfile
                logs/app.log
            }],
        },
        {
            name => 'backups',
            match => [qw{
                file.bak
                file.copy
                file~
                file~1
                file.orig
            }],
        },
        {
            name => 'vcs',
            match => [qw{
                .git
                .svn
                .bzr
                CVS/
                RCS/
                file,v
            }],
        },
        {
            name => 'build',
            match => [qw{
            }],
        },
        {
            name => '',
            match => [qw{
            }],
        },
        {
            name => '',
            match => [qw{
            }],
        },
        {
            name => '',
            match => [qw{
            }],
        },
        {
            name => '',
            match => [qw{
            }],
        },
        {
            name => '',
            match => [qw{
            }],
        },
        {
            name => '',
            match => [qw{
            }],
        },
        {
            name => '',
            match => [qw{
            }],
        },
        {
            name => '',
            match => [qw{
            }],
        },
    );

    my $files = File::TypeCategories->new();
    for my $type (@data) {
        for my $sample (@{ $type->{match} }) {
            ok $files->types_match($sample, $type->{name}), "$sample is a $type->{name}";
        }
    }
}
