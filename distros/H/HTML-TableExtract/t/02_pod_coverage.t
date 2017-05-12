use Test::More;
my $msg;
if (! $ENV{HTE_DEV_TESTS}) {
  $msg = "(dev only)";
}
else {
  eval "use Test::Pod::Coverage 1.00";
  $msg = "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
}
plan skip_all => $msg if $msg;
all_pod_coverage_ok({also_private => [qw/TREE parse eof/]});
