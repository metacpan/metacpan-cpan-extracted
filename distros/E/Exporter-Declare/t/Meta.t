#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Lite;
use aliased 'Exporter::Declare::Export::Sub';
use aliased 'Exporter::Declare::Export::Variable';

our $CLASS = "Exporter::Declare::Meta";
require_ok $CLASS;

tests construction => sub {
    my $meta = $CLASS->new('FakePackage');
    isa_ok( $meta, $CLASS );
    is( FakePackage->export_meta, $meta, "Linked" );
    is( $meta->package, 'FakePackage', "Got package" );
    is_deeply(
        $meta->exports,
        { '&FakePackage' => $meta->exports_get('FakePackage') },
        "Got export hash"
    );
    is_deeply(
        $meta->export_tags,
        { default => [], all => [ '&FakePackage' ], alias => ['FakePackage'] },
        "Got export tags"
    );
    is_deeply( $meta->options, {}, "Got options list" );
    is_deeply( $meta->arguments, { suffix => 1, prefix => 1 }, "Got arguments list" );
};

tests options => sub {
    my $meta = $CLASS->new('FakeOptionPackage');
    $meta->options_add($_) for qw/a b c/;
    is_deeply(
        [sort $meta->options_list],
        [qw/a b c/],
        "Got all options"
    );
};

tests arguments => sub {
    my $meta = $CLASS->new('FakeArgumentsPackage');
    $meta->arguments_add($_) for qw/a b c/;
    is_deeply(
        [sort $meta->arguments_list],
        [sort qw/a b c prefix suffix/],
        "Got all arguments"
    );
};

tests tags => sub {
    my $meta = $CLASS->new('FakeTagPackage');
    is_deeply(
        $meta->export_tags,
        { all => [ '&FakeTagPackage' ], alias => ['FakeTagPackage'], default => [] },
        "Export tags"
    );
    is_deeply( [$meta->export_tags_get('all')], [ '&FakeTagPackage' ], ':all only has alias' );
    is_deeply( [$meta->export_tags_get('default')], [], ':default is empty list' );

    $meta->export_tags_push( 'a', qw/a b c d/ );
    is_deeply( [$meta->export_tags_get('a')], [qw/a b c d/], "Added tag" );

    throws_ok { $meta->export_tags_push( 'all', "xxx" )}
        qr/'all' is a reserved tag, you cannot override it./,
        "Cannot modify 'all' tag";

    $meta->export_tags_push( 'default', qw/a b c d/ );
    is_deeply( [$meta->export_tags_get('default')], [qw/a b c d/], "updated default" );

    is_deeply(
        [sort $meta->export_tags_list],
        [sort
            'a',
            'alias',
            'all',
            'default'
        ],
        "Got list of all tags"
    );
};

tests exports => sub {
    my $meta = $CLASS->new('FakeExportPackage');

    my $code_no_sigil = Sub->new(sub {}, exported_by => 'FakeExportPackage' );
    $meta->exports_add( 'code_no_sigil', $code_no_sigil);
    is_deeply(
        $meta->exports->{ '&code_no_sigil' },
        $code_no_sigil,
        "Added export without sigil as code"
    );

    my $code_with_sigil = Sub->new(sub {}, exported_by => 'FakeExportPackage' );
    $meta->exports_add( '&code_with_sigil', $code_with_sigil);
    is_deeply(
        $meta->exports->{ '&code_with_sigil' },
        $code_with_sigil,
        "Added code export"
    );

    my $anon = "xxx";
    my $scalar = Variable->new( \$anon, exported_by => 'FakeExportPackage' );
    $meta->exports_add( '$scalar', $scalar );

    my $hash = Variable->new( {}, exported_by => 'FakeExportPackage' );
    $meta->exports_add( '%hash', $hash );

    my $array = Variable->new( [], exported_by => 'FakeExportPackage' );
    $meta->exports_add( '@array', $array );

    is_deeply(
        $meta->exports,
        {
            '&FakeExportPackage' => $meta->exports_get( 'FakeExportPackage' ),
            '&code_no_sigil'   => $code_no_sigil,
            '&code_with_sigil' => $code_with_sigil,
            '$scalar'          => $scalar,
            '%hash'            => $hash,
            '@array'           => $array,
        },
        "Added exports"
    );

    throws_ok { $meta->exports_add( '@array', $array )}
        qr/'\@array' already added for metric exports/,
        "Can't add an export twice";

    throws_ok { $meta->exports_add( '@array2', [] )}
        qr/Exports must be instances of 'Exporter::Declare::Export'/,
        "Can't add an export twice";

    is( $meta->exports_get( '$scalar'          ), $scalar,          "Got scalar export" );
    is( $meta->exports_get( '@array'           ), $array,           "Got array export"  );
    is( $meta->exports_get( '%hash'            ), $hash,            "Got hash export"   );
    is( $meta->exports_get( '&code_with_sigil' ), $code_with_sigil, "Got &code export"  );
    is( $meta->exports_get( 'code_no_sigil'    ), $code_no_sigil,   "Got code export"   );

    throws_ok { $meta->exports_get( '@array2' )}
        qr/FakeExportPackage does not export '\@array2'/,
        "Can't import whats not exported";

    throws_ok { $meta->exports_get( '-xxx' )}
        qr/exports_get\(\) does not accept a tag as an argument/,
        "Can't import whats not exported";

    throws_ok { $meta->exports_get( ':xxx' )}
        qr/exports_get\(\) does not accept a tag as an argument/,
        "Can't import whats not exported";

    is_deeply(
        [sort $meta->exports_list],
        [sort
            '$scalar',
            '@array',
            '%hash',
            '&code_with_sigil',
            '&FakeExportPackage',
            '&code_no_sigil'
        ],
        "Got a list of all exports"
    );
};

{
    package PackageToPull;

    sub a { 'a' }
    our $B = 'b';
    our @C = ( 'c' );
    our %D = ( 'D' => 'd' );
}

tests pull_from_package => sub {
    my $meta = $CLASS->new('PackageToPull');
    is_deeply(
        [$meta->get_ref_from_package( 'a' )],
        [ \&PackageToPull::a, '&a' ],
        "Puled a sub"
    );
    is_deeply(
        [$meta->get_ref_from_package( '&a' )],
        [ \&PackageToPull::a, '&a' ],
        "Puled a sub w/ sigil"
    );

    is_deeply(
        [$meta->get_ref_from_package( '$B' )],
        [ \$PackageToPull::B, '$B' ],
        "Puled scalar"
    );

    is_deeply(
        [$meta->get_ref_from_package( '@C' )],
        [ \@PackageToPull::C, '@C' ],
        "Puled array"
    );

    is_deeply(
        [$meta->get_ref_from_package( '%D' )],
        [ \%PackageToPull::D, '%D' ],
        "Puled hash"
    );
};

run_tests();
done_testing;
