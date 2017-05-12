use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

$SIG{__WARN__} = sub {
   my $msg = shift;
   return if ("$msg" =~ /Too late to run INIT block at .*Hook.Filter/i);
   CORE::warn($msg);
};

all_pod_coverage_ok();
