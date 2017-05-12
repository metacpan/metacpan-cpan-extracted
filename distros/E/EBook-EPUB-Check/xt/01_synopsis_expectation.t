use Test::More;
eval "use Test::Synopsis::Expectation";
plan skip_all => "Test::Synopsis::Expectation required for testing" if $@;
synopsis_ok('lib/EBook/EPUB/Check.pm');
done_testing;
