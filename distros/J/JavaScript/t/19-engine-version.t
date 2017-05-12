#!perl

use Test::More tests => 6;

use strict;
use warnings;

use JavaScript;

my $str = JavaScript->get_engine_version();
like($str, qr/JavaScript-C/, "Scalar get_engine_version");
like($str, qr/\b\d+\.\d+\b/);
like($str, qr/\b\d+-\d+-\d+\b/);

my ($engine, $version, $build_date) = JavaScript->get_engine_version(); 
is($engine, "JavaScript-C");
like($version, qr/\b\d+\.\d+\b/);
like($build_date, qr/\b\d+-\d+-\d+\b/);
