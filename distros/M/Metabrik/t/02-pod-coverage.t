eval "use Test::Pod::Coverage tests => 5";
if ($@) {
   use Test;
   plan(tests => 1);
   skip("Test::Pod::Coverage required for testing");
}
else {
   pod_coverage_ok("Metabrik");
   pod_coverage_ok("Metabrik::Core::Context");
   pod_coverage_ok("Metabrik::Core::Log");
   pod_coverage_ok("Metabrik::Core::Shell");
   pod_coverage_ok("Metabrik::Core::Global");
}
