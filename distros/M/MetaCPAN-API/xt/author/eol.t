use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/MetaCPAN/API.pm',
    'lib/MetaCPAN/API/Author.pm',
    'lib/MetaCPAN/API/Autocomplete.pm',
    'lib/MetaCPAN/API/Distribution.pm',
    'lib/MetaCPAN/API/Favorite.pm',
    'lib/MetaCPAN/API/File.pm',
    'lib/MetaCPAN/API/Module.pm',
    'lib/MetaCPAN/API/POD.pm',
    'lib/MetaCPAN/API/Rating.pm',
    'lib/MetaCPAN/API/Release.pm',
    'lib/MetaCPAN/API/Source.pm',
    't/_build_extra_params.t',
    't/_decode_result.t',
    't/author.t',
    't/autocomplete.t',
    't/distribution.t',
    't/favorite.t',
    't/fetch.t',
    't/file.t',
    't/lib/TestFunctions.pm',
    't/module.t',
    't/pod.t',
    't/post.t',
    't/rating.t',
    't/release.t',
    't/source.t',
    't/ua.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
