#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

my $params = {trustme => [
  qr/BUILD/,
  qr/DEMOLISH/,
  qr/True/,
  qr/False/,
  qr/xlCmdTableCollection/,
  qr/has_nonempty_keys/,
  qr/invalid_options/,
  qr/flatten_format_information/,
 ]};

all_pod_coverage_ok($params);



