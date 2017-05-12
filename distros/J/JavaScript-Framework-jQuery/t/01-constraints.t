#!perl -T

use warnings;
use strict;

use Test::More tests => 8;
use JavaScript::Framework::jQuery::Subtypes ':all';

my (
    $data,
    $expected,
);

# cssAsset

$data = {
    href => '',
    media => '',
};

ok(is_cssAsset($data), 'data is valid cssAsset');

$data = {
    href => '',
    media => '',
    charlie => '',
};

ok(! is_cssAsset($data), 'data is NOT valid cssAsset');

# cssAssetList

$data = [
    {
        href => '',
        media => '',
    },
    {
        href => '',
        media => '',
    },
    {
        href => '',
        media => '',
    },
];
ok(is_cssAssetList($data), 'data is valid cssAssetList');

$data = [
    {
        href => '',
        media => '',
    },
    {
        href => '',
        media => '',
    },
    {
        href => '',
        media => '',
    },
    {
        href => '',
        media => '',
    },
    {
        href => '',
        media => '',
    },
];
ok(is_cssAssetList($data), 'data is valid cssAssetList');

# libraryAssets
$data = {
    src => [
        qw/word word1 word2/
    ],
    css => [
        { href => '', media => '' },
        { href => '', media => '' },
    ],
};
ok(is_libraryAssets($data), 'data is valid libraryAssets');

$data = {
    src => [],
    css => [
    'foo'
    ],
};
ok(! is_libraryAssets($data), 'data is NOT a valid libraryAssets');

# pluginAssets
$data = [
    {
        name => 'MyPlugin ',
        library => {
            src => [],
            css => [
                { href => '', media => '' },
                { href => '', media => '' },
            ],
        },
    },
];
ok(is_pluginAssets($data), 'data is valid pluginAssets');

$data = [
    {
        name => 'MyPlugin',
        library => {
            src => [],
            css42 => [                              # invalid key name
                { href => '', media => '' },
                { href => '', media => '' },
            ],
        },
    },
];
ok(! is_pluginAssets($data), 'data is NOT a valid pluginAssets');

# coercions

$expected = '{
   "bar" : "Zeppos",
   "foo" : 42
}';

$data = {
    foo => 42,
    bar => 'Zeppos',  # great times in the 70s - you had to have been there
};


