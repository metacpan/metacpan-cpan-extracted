#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Lite;
use aliased 'Exporter::Declare::Meta';
use aliased 'Exporter::Declare::Export::Sub';
use aliased 'Exporter::Declare::Export::Variable';

our $CLASS = "Exporter::Declare::Specs";
require_ok $CLASS;

sub TestPackage { 'TestPackage' }

our $META = Meta->new( TestPackage );

$META->exports_add(
    $_,
    Sub->new( sub {}, exported_by => __PACKAGE__ )
) for qw/x X xx XX/;

my %vars;
$META->exports_add(
    "\$$_",
    Variable->new( \$vars{$_}, exported_by => __PACKAGE__ )
) for qw/y Y yy YY/;

$META->exports_add(
    "\@$_",
    Variable->new( [$_], exported_by => __PACKAGE__ )
) for qw/z Z zz ZZ/;

$META->export_tags_push( 'xxx', qw/x $y @z/ );
$META->export_tags_push( 'yyy', qw/X $Y @Z/ );

$META->arguments_add( 'foo' );

tests construction => sub {
    my $spec = $CLASS->new( TestPackage );
    isa_ok( $spec, $CLASS );
    is( $spec->package, TestPackage, "Stored Package" );
    isa_ok( $spec->config, 'HASH', "Config" );
    isa_ok( $spec->exports, 'HASH', "Exports" );
    isa_ok( $spec->excludes, 'ARRAY', "Excludes" );
};

tests util => sub {
    my $spec = $CLASS->new( TestPackage );
    is( Exporter::Declare::Specs::_item_name('a' ), '&a', "Added sigil" );
    is( Exporter::Declare::Specs::_item_name('&a'), '&a', "kept sigil"  );
    is( Exporter::Declare::Specs::_item_name('$a'), '$a', "kept sigil"  );
    is( Exporter::Declare::Specs::_item_name('%a'), '%a', "kept sigil"  );
    is( Exporter::Declare::Specs::_item_name('@a'), '@a', "kept sigil"  );

    is(
        Exporter::Declare::Specs::_get_item($spec, 'X'),
        $META->exports_get( 'X' ),
        "_exports_get"
    );

    is_deeply(
        [ Exporter::Declare::Specs::_export_tags_get($spec, 'xxx')],
        [ $META->export_tags_get( 'xxx' )],
        "_exports_get"
    );
};

tests exclude_list => sub {
    my $spec = $CLASS->new( TestPackage );
    is_deeply( $spec->excludes, [], "no excludes" );
    $spec->_exclude_item( $_ ) for qw/a &b $c %d @e/;
    is_deeply( $spec->excludes, [qw/&a &b $c %d @e/], "excludes" );
    $spec->_exclude_item( $_ ) for qw/q r -xxx :yyy/;
    is_deeply(
        $spec->excludes,
        [qw/&a &b $c %d @e &q &r &x $y @z &X $Y @Z/],
        "exclude tags"
    );
};

tests include_list => sub {
    my $spec = $CLASS->new( TestPackage );
    is_deeply( $spec->exports, {}, "Exports is an empty hash" );
    $spec->_include_item( 'XX' );
    lives_ok { $spec->_include_item( 'XX' ) } "Multiple add is no-op";
    is_deeply(
        $spec->exports,
        { '&XX' => [ $META->exports_get( 'XX' ), {}, [] ]},
        "Added export"
    );
    $spec->_include_item( 'XX', { -a => 'a' }, ['a'] );
    is_deeply(
        $spec->exports,
        { '&XX' => [ $META->exports_get( 'XX' ), { a => 'a' }, ['a'] ]},
        "Added export config"
    );
    $spec->_include_item( 'XX', { -a => 'a', -b => 'b', x => 'y' }, ['a', 'b'] );
    is_deeply(
        $spec->exports,
        { '&XX' => [ $META->exports_get( 'XX' ), { a => 'a', b => 'b' }, ['a', 'a', 'b', 'x', 'y' ] ]},
        "combined configs"
    );

    $spec->_include_item( '-xxx', { -tag => 1, 'param' => 'p' }, [ 'from tag' ] );
    is_deeply(
        $spec->exports,
        {
            '&XX' => [ $META->exports_get( 'XX' ), { a => 'a', b => 'b' }, [ 'a', 'a', 'b', 'x', 'y' ]],
            '&x'  => [ $META->exports_get( '&x' ), { tag => 1 }, [ 'from tag', 'param', 'p' ]],
            '$y'  => [ $META->exports_get( '$y' ), { tag => 1 }, [ 'from tag', 'param', 'p' ]],
            '@z'  => [ $META->exports_get( '@z' ), { tag => 1 }, [ 'from tag', 'param', 'p' ]],
        },
        "included tag, with config"
    );
};

tests acceptance => sub {
    my $spec = $CLASS->new( TestPackage,
        qw/ $YY @ZZ &xx $yy @zz X $Y @Z !:xxx !$YY /,
        XX    => [ 'a', 'b' ],
        '&xx' => { -as => 'apple', -args => [ 'o' ], a => 'b' },
        -yyy  => { -prefix => 'uhg_', -suffix => '_blarg' },
        -foo  => 'bar',
        -prefix => 'aaa_',
    );
    is_deeply(
        $spec->excludes,
        [qw/ &x $y @z $YY/],
        "Excludes"
    );
    my $exp = sub { $META->exports_get(@_)};
    is_deeply(
        $spec->exports,
        {
            '@ZZ' => [ $exp->('@ZZ'), {}, []],
            '&XX' => [ $exp->('&XX'), {}, [ 'a', 'b' ]],
            '&xx' => [ $exp->('&xx'), { as => 'apple' }, [ 'o', 'a', 'b' ]],
            '$yy' => [ $exp->('$yy'), {}, []],
            '@zz' => [ $exp->('@zz'), {}, []],
            '&X'  => [ $exp->('&X' ), { prefix => 'uhg_', suffix => '_blarg' }, []],
            '$Y'  => [ $exp->('$Y' ), { prefix => 'uhg_', suffix => '_blarg' }, []],
            '@Z'  => [ $exp->('@Z' ), { prefix => 'uhg_', suffix => '_blarg' }, []],
        },
        "Export list"
    );
    is_deeply(
        $spec->config,
        {
            foo => 'bar',
            prefix => 'aaa_',
            yyy => { -prefix => 'uhg_', -suffix => '_blarg' },
            xxx => '',
        },
        "Config"
    );

    {
        local $SIG{__WARN__} = sub {};
        $spec->export('FakePackage');
    }

    can_ok( 'FakePackage', qw/apple aaa_XX uhg_X_blarg/ );
    no strict 'refs';
    isa_ok( \&{"FakePackage\::$_"}, Sub ) for qw/apple aaa_XX uhg_X_blarg/;
    isa_ok( \${"FakePackage\::$_"}, Variable ) for qw/aaa_yy uhg_Y_blarg/;
    isa_ok( \@{"FakePackage\::$_"}, Variable ) for qw/aaa_ZZ aaa_zz uhg_Z_blarg/;
};

tests inject_api => sub {
    my $spec = $CLASS->new( TestPackage );
    ok( !$spec->exports->{'&foo'}, "no foo export" );
    $spec->add_export( '&foo' => sub { 'foo' });
    ok( $spec->exports->{'&foo'}, "foo export" );
    isa_ok( $spec->exports->{'&foo'}->[0], 'Exporter::Declare::Export::Sub' );
    my $test_dest = 'Test::ExDec::Inject::API';
    $spec->export( $test_dest );
    can_ok( $test_dest, 'foo' );
    is( $test_dest->can( 'foo' ), $spec->exports->{'&foo'}->[0], "sanity check" );
};

run_tests;
done_testing;
