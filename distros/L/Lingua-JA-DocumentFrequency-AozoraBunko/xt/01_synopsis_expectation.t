use Test::More;
eval "use Test::Synopsis::Expectation";
plan skip_all => "Test::Synopsis::Expectation required for testing" if $@;
synopsis_ok('Lib/Lingua/JA/DocumentFrequency/AozoraBunko.pm');
done_testing;
