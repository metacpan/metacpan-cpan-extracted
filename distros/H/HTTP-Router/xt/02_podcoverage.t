use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok({
    trustme      => [qw(new)],
    also_private => [qw(
        create_match create_with create_resources create_resource
        routing
        to_request
    )]
});
