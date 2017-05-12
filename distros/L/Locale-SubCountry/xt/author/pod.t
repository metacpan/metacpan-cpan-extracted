use Test::More;
eval "use Test::Pod 1.04";
plan skip_all => "Test::Pod 1.04 required for testing POD" if $@;
plan tests => 1;
pod_file_ok('lib/Locale/SubCountry.pm','POD ok for SubCountry.pm');
