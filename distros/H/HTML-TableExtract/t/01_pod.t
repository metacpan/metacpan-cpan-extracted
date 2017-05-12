use Test::More;
my $msg;
if (! $ENV{HTE_DEV_TESTS}) {
  $msg = "(dev only)";
}
else {
  eval "use Test::Pod 1.00";
  $msg = "Test::Pod 1.00 or greater required for testing POD" if $@;
}
plan skip_all => $msg if $msg;
all_pod_files_ok();
