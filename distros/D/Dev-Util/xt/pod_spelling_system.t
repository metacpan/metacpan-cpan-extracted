#!/usr/bin/env perl

use Test2::V0;
use Test2::Require::AuthorTesting;

use Dev::Util::Syntax;

use Test2::Require::Module 'Test::Spelling' => '0.25';
use Test::Spelling;
use Test2::Require::Module 'Pod::Wordlist' => '1.27';
use Pod::Wordlist;
use Test2::Require::Module 'YAML' => '1.30';
use YAML qw( LoadFile );

my $config_filename = 'xt/spell_whitelist.yml';

my $config;
$config = LoadFile($config_filename)
    if -r $config_filename;

plan skip_all => 'disabled' if $config->{ pod_spelling_system }->{ skip };

add_stopwords( $config->{ pod_spelling_system }->{ stopwords }->@* );
add_stopwords(
               qw(
                   os AIX BSD FreeBSD MSWin32 NetBSD OpenBSD OpenVMS
                   RedHat Solaris SunOS MacOS AUX OSX

                   API APIs

                   CPAN AnnoCPAN XS DBI Readonly readonly

                   FH STDERR STDIN STDOUT stderr stdin stdout

                   JSON JavaScript
                   CGI URI URL
                   SQLite
                   PDF PDFs
                   YAML

                   IP SSL TCP UDP loopback noecho

                   TLDR TODO

                   ascii
                   CMD cmd cmds
                   dir dirs subdirectory
                   filename filenames
                   hostname hostnames
                   lib
                   login
                   msg
                   munge
                   namespace
                   optimizations
                   pluggable
                   plugins
                   portably
                   reinstall
                   standalone
                   timestamp timestamps
                   uncommented
                   unencrypted
                   username usernames
               )
             );
all_pod_files_spelling_ok(qw(lib bin examples));

done_testing;
