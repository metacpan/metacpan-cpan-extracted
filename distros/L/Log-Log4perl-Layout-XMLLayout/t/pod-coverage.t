use Test::More 'no_plan';
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
pod_coverage_ok( q(Log::Log4perl::Layout::XMLLayout),
  { also_private => [ qr/^(current_time|render)$/ ], },
  "private functions are not POD covered",);