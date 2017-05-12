#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;

use ExtUtils::FakeConfig make => 'my_make',
                         cc => 'my_cc',
                         xxrv => 'dummy';
use Config;

is( $Config{make}, 'my_make' );
is( $Config{cc}, 'my_cc' );
is( $Config{xxrv}, 'dummy' );
