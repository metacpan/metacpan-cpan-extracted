#!/usr/bin/perl -w

use Test::More;
use Test::Pod;

plan skip_all => "export AUTHOR_TEST for author tests" unless $ENV{AUTHOR_TEST};

all_pod_files_ok( grep {!/~$/} all_pod_files( qw(pods lib scripts/) ) );



