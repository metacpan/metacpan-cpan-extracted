use Test::More;
BEGIN {
    plan skip_all => 'Plack required for server conformance tests'
        unless eval { require Plack::Test::Suite; 1 };
}
Plack::Test::Suite->run_server_tests('Hyperman');
done_testing;
