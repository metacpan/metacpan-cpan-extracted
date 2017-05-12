use Test::More;

eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;

my $trustme = {
               trustme => [qr/^(?:new)$/],
               coverage_class => 'Pod::Coverage::CountParents'
              };
all_pod_coverage_ok($trustme);

done_testing();
