use warnings;
use strict;
use Test::More;

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
  if $@;

my @modules = all_modules();
my $trustme = { trustme => [qr/^(SYS_|linux|unix)/] };

foreach my $module (@modules) {
    pod_coverage_ok( $module, $trustme, 'Pod coverage is ok' );
}

done_testing();
