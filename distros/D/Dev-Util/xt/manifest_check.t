#!/usr/bin/env perl

use 5.018;
use Test2::V0;
use Test2::Bundle::More;
use Test2::Require::AuthorTesting;
use ExtUtils::Manifest;

is_deeply( [ ExtUtils::Manifest::manicheck() ],
           [], 'Missing Files from Manifest' );
is_deeply( [ ExtUtils::Manifest::filecheck() ],
           [], 'Extra Files in Manifest' );

done_testing;

