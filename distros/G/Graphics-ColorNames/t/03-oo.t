#!/usr/bin/perl

use Test::Most;

use lib 't/lib';

use_ok('Graphics::ColorNames');

my $s = Graphics::ColorNames->new;
isa_ok $s, 'Graphics::ColorNames';

subtest 'hex' => sub {

    is $s->hex('darkgreen'),  '006400', 'darkgreen';
    is $s->hex('Dark Green'), '006400', 'Dark Green';
    is $s->hex('Dark-Green'), '006400', 'Dark-Green';
    is $s->hex('Dark_Green'), '006400', 'Dark-Green';

    is $s->hex( 'darkgreen', '#' ),  '#006400',  'darkgreen (prefix)';
    is $s->hex( 'darkgreen', '0x' ), '0x006400', 'darkgreen (prefix)';

    is $s->hex('dorkreen'), '', 'nonexistenct color';
    is $s->hex( 'dorkreen', '#' ), '', 'nonexistenct color with prefix';

    is $s->hex('123abc')   => '123abc', 'passthru';
    is $s->hex('#123abc')  => '123abc', 'passthru (# prefix)';
    is $s->hex('0x123abc') => '123abc', 'passthru (0x prefix)';

};

subtest 'rgb' => sub {

    is_deeply [ $s->rgb('darkgreen') ],  [ 0, 0x64, 0 ], 'darkgreen';
    is_deeply [ $s->rgb('DarkGreen') ],  [ 0, 0x64, 0 ], 'DarkGreen';
    is_deeply [ $s->rgb('Dark-Green') ], [ 0, 0x64, 0 ], 'Dark-Green';
    is_deeply [ $s->rgb('Dark_Green') ], [ 0, 0x64, 0 ], 'Dark_Green';

    is_deeply [ $s->rgb( 'darkgreen', ',' ) ], [ 0, 0x64, 0 ],
      'darkgreen (separator ignored in list context)';

    is $s->rgb('darkgreen'), "0,100,0", 'darkgreen (scalar)';
    is $s->rgb( 'darkgreen', ' ' ), "0 100 0",
      'darkgreen (scalar with separator)';

    is_deeply [ $s->rgb('dorkreen') ], [], 'nonexistent color';
    is $s->rgb('dorkreen'), '', 'nonexistent color (scalar context)';
    is $s->rgb( 'dorkreen', ' ' ), '',
      'nonexistent color (scalar context with separator)';

    is_deeply [ $s->rgb('123abc') ] => [ 18, 58, 188 ],
      'passthru (list context)';
    is $s->rgb('123abc') => '18,58,188', 'passthru';
    is $s->rgb( '123abc', ' ' ) => '18 58 188', 'passthru (with separator)';
    is $s->rgb('#123abc')  => '18,58,188', 'passthru (# prefix)';
    is $s->rgb('0x123abc') => '18,58,188', 'passthru (0x prefix)';

};

subtest 'load_scheme' => sub {

    is $s->hex('nonexistentcolorname') => '', 'unknown color';

    ok $s->load_scheme( { nonexistentcolorname => 0x123456 } ), 'load_scheme';

    is $s->hex('nonexistentcolorname') => '123456', 'loaded color';

};

subtest 'autoloading removed' => sub {

    ok $s->rgb('darkgreen'), 'has darkgreen color';

    ok !$s->can('darkgreen'), 'no darkgreen method';

};

done_testing;
