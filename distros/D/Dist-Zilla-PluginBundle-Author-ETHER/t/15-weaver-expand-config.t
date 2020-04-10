use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::Fatal;

use Pod::Weaver::PluginBundle::Author::ETHER;
use Pod::Weaver::Config::Assembler;
sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

my @bad_data = (
    [ { a => 1 }, qr/unrecognized config format: HASH/ ],
    [ undef, qr/undefined config/ ],
    [ [ Name => { ':version' => '999' } ], qr/Pod::Weaver::Section::Name version 999 required/ ],
);

foreach my $bad_data (@bad_data) {
    like(
        exception { Pod::Weaver::PluginBundle::Author::ETHER->_expand_config($bad_data->[0]) },
        $bad_data->[1],
        'exception from bad data',
   );
}

# test label => original data => expected transformation
my @test_data = (
    [ 'plugin bundle, no parameters' =>
        '@Foo'                              => [ '@Author::ETHER/Foo', _exp('@Foo'), {} ] ],
    [ 'plugin, no parameters' =>
        '-Foo'                              => [ '@Author::ETHER/Foo', _exp('-Foo'), {} ], => 'plugin, no parameters' ],
    [ 'section, no parameters' =>
        'Foo'                               => [ '@Author::ETHER/Foo', _exp('Foo'), {} ] => 'section, no parameters' ],
    [ 'plugin, with parameters' =>
        [ '-Foo' => { foo => 'bar' } ]      => [ '@Author::ETHER/Foo', _exp('-Foo'), { foo => 'bar' } ] ],
    [ 'section, with parameters' =>
        [ 'Foo' => { foo => 'bar' } ]       => [ '@Author::ETHER/Foo', _exp('Foo'), { foo => 'bar' } ] ],

    [ 'plugin, with name, no parameters' =>
        [ '-Foo' => 'Bar' ]                 => [ '@Author::ETHER/Bar', _exp('-Foo'), {} ] ],
    [ 'section, with name, no parameters' =>
        [ 'Foo' => 'Bar' ]                  => [ '@Author::ETHER/Bar', _exp('Foo'), {} ] ],

    [ 'plugin, with name and parameters' =>
        [ '-Foo' => 'Bar' => { foo => 'bar' } ]      => [ '@Author::ETHER/Bar', _exp('-Foo'), { foo => 'bar' } ] ],
    [ 'section, with name and parameters' =>
        [ 'Foo' => 'Bar' => { foo => 'bar' } ]       => [ '@Author::ETHER/Bar', _exp('Foo'), { foo => 'bar' } ] ],

    [ 'named region, no parameters' =>
        [ 'Region' => 'prelude' ]           => [ '@Author::ETHER/prelude', _exp('Region'), { region_name => 'prelude'  } ] ],
    [ 'generic named section' =>
        [ 'Generic' => 'FOO' ]              => [ 'FOO', _exp('Generic'), {} ] ],
    [ 'named collector' =>
        [ 'Collect' => 'FOO', { command => 'foo' } ] => [ 'FOO', _exp('Collect'), { command => 'foo' } ] ],
);

foreach my $test_data (@test_data) {
    cmp_deeply(
        Pod::Weaver::PluginBundle::Author::ETHER->_expand_config($test_data->[1]),
        $test_data->[2],
        $test_data->[0],
    );
}

# Also test the outcome of my bundle's ->mvp_bundle_config against its original contents.
cmp_deeply(
    [
        map Pod::Weaver::PluginBundle::Author::ETHER->_expand_config($_),
            '@CorePrep',
            '-SingleEncoding',
            'Name',
            'Version',
            [ 'Region' => 'prelude' ],
            [ 'Generic' => 'SYNOPSIS' ],
            [ 'Generic' => 'DESCRIPTION' ],
            [ 'Generic' => 'OVERVIEW' ],
            [ 'Collect' => 'ATTRIBUTES' => { command => 'attr' } ],
            [ 'Collect' => 'METHODS'    => { command => 'method' } ],
            [ 'Collect' => 'FUNCTIONS'  => { command => 'func' } ],
            'Leftovers',
            [ 'Region' => 'postlude' ],
            'Authors',
            [ 'Contributors' => { ':version' => '0.008' } ],
            'Legal',
            [ '-Transformer' => List => { transformer => 'List' } ],
    ],
    [
        [ '@Author::ETHER/CorePrep',        _exp('@CorePrep'), {} ],
        [ '@Author::ETHER/SingleEncoding',  _exp('-SingleEncoding'), {} ],
        [ '@Author::ETHER/Name',            _exp('Name'),      {} ],
        [ '@Author::ETHER/Version',         _exp('Version'),   {} ],
        [ '@Author::ETHER/prelude',         _exp('Region'),    { region_name => 'prelude'  } ],
        [ 'SYNOPSIS',                       _exp('Generic'),   {} ],
        [ 'DESCRIPTION',                    _exp('Generic'),   {} ],
        [ 'OVERVIEW',                       _exp('Generic'),   {} ],
        [ 'ATTRIBUTES',                     _exp('Collect'),   { command => 'attr'   } ],
        [ 'METHODS',                        _exp('Collect'),   { command => 'method' } ],
        [ 'FUNCTIONS',                      _exp('Collect'),   { command => 'func'   } ],
        [ '@Author::ETHER/Leftovers',       _exp('Leftovers'), {} ],
        [ '@Author::ETHER/postlude',        _exp('Region'),    { region_name => 'postlude' } ],
        [ '@Author::ETHER/Authors',         _exp('Authors'),   {} ],
        [ '@Author::ETHER/Contributors',    _exp('Contributors'), { ':version' => '0.008' } ],
        [ '@Author::ETHER/Legal',           _exp('Legal'),     {} ],
        [ '@Author::ETHER/List',            _exp('-Transformer'), { 'transformer' => 'List' } ],
    ],
    'original mvp_bundle_config matches the transformed version',
);

done_testing;
