#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';
use Test::More;
use ExtUtils::Manifest;

plan skip_all => 'for authors only -- define $ENV{AUTHOR_TESTING}' unless ( $ENV{AUTHOR_TESTING} ||  $ENV{RELEASE_TESTING} );
plan tests => 2;

is_deeply [ ExtUtils::Manifest::manicheck() ], [], 'missing';
is_deeply [ ExtUtils::Manifest::filecheck() ], [], 'extra';
