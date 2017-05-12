use Test::More;
eval "use Test::Synopsis::Expectation";
plan skip_all => "Test::Synopsis::Expectation required for testing" if $@;
synopsis_ok('lib/Lingua/JA/NormalizeText.pm');
done_testing;
