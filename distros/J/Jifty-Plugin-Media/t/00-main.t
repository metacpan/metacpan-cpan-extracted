#!/usr/bin/env perl

use warnings;
use strict;
use utf8;

use Test::More tests => 6;
use_ok('Jifty::Plugin::Media');

my $string = 'with_accent_é_&_slash/_is';

is( Jifty::Plugin::Media->clean_dir_name($string), 'with_accent_e_-_slash-_is', "clean dir name with accent slash and &");

is( Jifty::Plugin::Media->clean_file_name($string), 'with_accent_e_-_slash-_is', "clean file name whithout extension");

$string = 'with_pipe: | & white_space.sém';
is( Jifty::Plugin::Media->clean_file_name($string), 'with_pipe-white_space.sem', "clean file name whith extension");

$string = 'with_point: . & white_space.sém';
is( Jifty::Plugin::Media->clean_file_name($string), 'with_point-white_space.sem', "clean file name whith extension and point in name");

$string = 'with_pipe: | & white_space.some strange ext';
is( Jifty::Plugin::Media->clean_file_name($string), 'with_pipe-white_space-some-strange-ext', "clean file name whith weird extension");

