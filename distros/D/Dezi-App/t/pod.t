#!perl

use strict;
use warnings;

use Test::More;
use Class::Load qw(try_load_class);

plan skip_all => "set RELEASE_TESTING to test POD" unless $ENV{RELEASE_TESTING};

my $min_tp_version = 1.14;
try_load_class( 'Test::Pod', { -version => $min_tp_version } )
  or plan skip_all => "Test::Pod $min_tp_version required for testing POD";

Test::Pod::all_pod_files_ok();
