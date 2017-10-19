#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Debian::Dependency');

};

my $plain = eval{ Debian::Dependency->new('perl') };
ok( !$@, 'simple Dep constructed' );
is( $plain->pkg, 'perl', 'name parsed correctly' );
is( $plain->rel, undef, "plain dependency has no relation" );
is( $plain->ver, undef, "plain dependency has no version" );

my $ver   = eval { Debian::Dependency->new('libfoo', '5.6') };
ok( !$@, 'versioned Dep constructed' );
is( $ver->pkg, 'libfoo', 'versioned name parsed' );
is( $ver->ver, '5.6', 'oversion parsed' );
is( $ver->rel, '>=', '>= relation parsed' );

$ver = eval { Debian::Dependency->new('libfoo (>= 5.6)') };
ok( !$@, 'versioned Dep parsed' );
is( $ver->pkg, 'libfoo', 'package of ver dep' );
is( $ver->rel, '>=', 'relation of ver dep' );
is( $ver->ver, '5.6', 'version of ver dep' );
is( "$ver", 'libfoo (>= 5.6)', 'Versioned Dep stringified' );

my $loe = eval { Debian::Dependency->new('libbar (<= 1.2)') };
ok( !$@, '<= dependency parsed' );
is( $loe->rel, '<=', '<= dependency detected' );

{
    my $d = eval { Debian::Dependency->new('libbar (< 1.2)') };
    ok(!$@, '< dependency parsed');
    is($d->rel, '<=', '< dependency detected as <=');
}

{
    my $d = eval { Debian::Dependency->new('libbar (> 1.2)') };
    ok(!$@, '> dependency parsed');
    is($d->rel, '>=', '> dependency detected as >=');
}

my $se = eval { Debian::Dependency->new('libfoo-perl (=1.2)') };
ok( !$@, '= dependency parsed' );
is( $se->rel, '=', '= dependency detected' );

my $d = Debian::Dependency->new( 'foo', '0' );
is( "$d", 'foo', 'zero version is ignored when given in new' );

$d = Debian::Dependency->new( 'foo', '0.000' );
is( "$d", 'foo', '0.000 version is ignored when given in new' );

$d = Debian::Dependency->new('libfoo (>= 0.000)');
is( "$d", 'libfoo', 'zero version is ignored when parsing' );

$d = new_ok( 'Debian::Dependency', [ [ 'foo', 'bar' ] ] );
isa_ok( $d->alternatives, 'ARRAY' );
is( $d->alternatives->[0] . "", 'foo', "first alternative is foo" );
is( $d->alternatives->[1] . "", 'bar', "second alternative is bar" );
$d = new_ok( 'Debian::Dependency', [ 'foo | bar' ] );
isa_ok( $d->alternatives, 'ARRAY' );
is( "$d", "foo | bar", "alternative dependency stringifies" );

# architectures and build-profiles
my $abp = eval { Debian::Dependency->new('libfoo [amd64]') };
ok( !$@, 'dep with 1 architecture parsed' );
$abp = eval { Debian::Dependency->new('libfoo [amd64 i396]') };
ok( !$@, 'dep with 2 architectures parsed' );
$abp = eval { Debian::Dependency->new('libfoo (>= 42) [amd64]') };
ok( !$@, 'dep with version and 1 architecture parsed' );
$abp = eval { Debian::Dependency->new('libfoo (>= 42) [amd64 i396]') };
ok( !$@, 'dep with version and 2 architectures parsed' );
$abp = eval { Debian::Dependency->new('libfoo <stage1>') };
ok( !$@, 'dep with 1 build profile parsed' );
$abp = eval { Debian::Dependency->new('libfoo <stage1> <stage2>') };
ok( !$@, 'dep with 2 separate build profiles parsed' );
$abp = eval { Debian::Dependency->new('libfoo <stage1 cross>') };
ok( !$@, 'dep with 1 build profile with 2 terms parsed' );
$abp = eval { Debian::Dependency->new('libfoo <!stage1> <!cross>') };
ok( !$@, 'dep with 2 separate negated build profiles parsed' );
$abp = eval { Debian::Dependency->new('libfoo (>= 23) <stage1>') };
ok( !$@, 'dep with version and build profile parsed' );
$abp = eval { Debian::Dependency->new('libfoo [amd64] <stage1>') };
ok( !$@, 'dep with architecture and build profile parsed' );
$abp = eval { Debian::Dependency->new('libfoo (>= 23) [amd64] <stage1>') };
ok( !$@, 'dep with version and architecture and build profile parsed' );

sub sat( $ $ $ ) {
    my( $dep, $test, $expected ) = @_;

    ok( $dep->satisfies($test) == $expected, "$dep ".($expected ? 'satisfies' : "doesn't satisfy"). " $test" );
}

my $dep = Debian::Dependency->new('foo');
sat( $dep, 'bar', 0 );
sat( $dep, 'foo', 1 );
sat( $dep, 'foo (>> 4)', 0 );
sat( $dep, 'foo (>= 4)', 0 );
sat( $dep, 'foo (= 4)',  0 );
sat( $dep, 'foo (<= 4)', 0 );
sat( $dep, 'foo (<< 4)', 0 );

$dep = Debian::Dependency->new('foo (>> 4)');
sat( $dep, 'bar', 0 );
sat( $dep, 'foo', 1 );

sat( $dep, 'foo (>> 3)', 1 );
sat( $dep, 'foo (>= 3)', 1 );
sat( $dep, 'foo (= 3)',  0 );
sat( $dep, 'foo (<= 3)', 0 );
sat( $dep, 'foo (<< 3)', 0 );

sat( $dep, 'foo (>> 4)', 1 );
sat( $dep, 'foo (>= 4)', 1 );
sat( $dep, 'foo (= 4)',  0 );
sat( $dep, 'foo (<= 4)', 0 );
sat( $dep, 'foo (<< 4)', 0 );

sat( $dep, 'foo (>> 5)', 0 );
sat( $dep, 'foo (>= 5)', 0 );
sat( $dep, 'foo (= 5)',  0 );
sat( $dep, 'foo (<= 5)', 0 );
sat( $dep, 'foo (<< 5)', 0 );

$dep = Debian::Dependency->new('foo (>= 4)');
sat( $dep, 'bar', 0 );
sat( $dep, 'foo', 1 );

sat( $dep, 'foo (>> 4)', 0 );
sat( $dep, 'foo (>= 4)', 1 );
sat( $dep, 'foo (= 4)',  0 );
sat( $dep, 'foo (<= 4)', 0 );
sat( $dep, 'foo (<< 4)', 0 );

sat( $dep, 'foo (>> 3)', 1 );
sat( $dep, 'foo (>= 3)', 1 );
sat( $dep, 'foo (= 3)',  0 );
sat( $dep, 'foo (<= 3)', 0 );
sat( $dep, 'foo (<< 3)', 0 );

sat( $dep, 'foo (>> 5)', 0 );
sat( $dep, 'foo (>= 5)', 0 );
sat( $dep, 'foo (= 5)',  0 );
sat( $dep, 'foo (<= 5)', 0 );
sat( $dep, 'foo (<< 5)', 0 );

$dep = Debian::Dependency->new('foo (= 4)');
sat( $dep, 'bar', 0 );
sat( $dep, 'foo', 1 );

sat( $dep, 'foo (>> 4)', 0 );
sat( $dep, 'foo (>= 4)', 1 );
sat( $dep, 'foo (= 4)',  1 );
sat( $dep, 'foo (<= 4)', 1 );
sat( $dep, 'foo (<< 4)', 0 );

sat( $dep, 'foo (>> 3)', 1 );
sat( $dep, 'foo (>= 3)', 1 );
sat( $dep, 'foo (= 3)',  0 );
sat( $dep, 'foo (<= 3)', 0 );
sat( $dep, 'foo (<< 3)', 0 );

sat( $dep, 'foo (>> 5)', 0 );
sat( $dep, 'foo (>= 5)', 0 );
sat( $dep, 'foo (= 5)',  0 );
sat( $dep, 'foo (<= 5)', 1 );
sat( $dep, 'foo (<< 5)', 1 );

$dep = Debian::Dependency->new('foo (<= 4)');
sat( $dep, 'bar', 0 );
sat( $dep, 'foo', 1 );

sat( $dep, 'foo (>> 4)', 0 );
sat( $dep, 'foo (>= 4)', 0 );
sat( $dep, 'foo (= 4)',  0 );
sat( $dep, 'foo (<= 4)', 1 );
sat( $dep, 'foo (<< 4)', 0 );

sat( $dep, 'foo (>> 3)', 0 );
sat( $dep, 'foo (>= 3)', 0 );
sat( $dep, 'foo (= 3)',  0 );
sat( $dep, 'foo (<= 3)', 0 );
sat( $dep, 'foo (<< 3)', 0 );

sat( $dep, 'foo (>> 5)', 0 );
sat( $dep, 'foo (>= 5)', 0 );
sat( $dep, 'foo (= 5)',  0 );
sat( $dep, 'foo (<= 5)', 1 );
sat( $dep, 'foo (<< 5)', 1 );

$dep = Debian::Dependency->new('foo (<< 4)');
sat( $dep, 'bar', 0 );
sat( $dep, 'foo', 1 );

sat( $dep, 'foo (>> 4)', 0 );
sat( $dep, 'foo (>= 4)', 0 );
sat( $dep, 'foo (= 4)',  0 );
sat( $dep, 'foo (<= 4)', 1 );
sat( $dep, 'foo (<< 4)', 1 );

sat( $dep, 'foo (>> 3)', 0 );
sat( $dep, 'foo (>= 3)', 0 );
sat( $dep, 'foo (= 3)',  0 );
sat( $dep, 'foo (<= 3)', 0 );
sat( $dep, 'foo (<< 3)', 0 );

sat( $dep, 'foo (>> 5)', 0 );
sat( $dep, 'foo (>= 5)', 0 );
sat( $dep, 'foo (= 5)',  0 );
sat( $dep, 'foo (<= 5)', 1 );
sat( $dep, 'foo (<< 5)', 1 );

$dep = Debian::Dependency->new('foo (<< 4) | bar ');
sat( $dep, 'foo', 0 );
sat( $dep, 'bar', 0 );

$dep = Debian::Dependency->new('foo (<< 4)');
sat( $dep, 'foo | bar', 1 );
sat( $dep, 'foo (<= 5) | zoo', 1 );
sat( $dep, 'zoo', 0 );

sub comp {
    my( $one, $two, $expected ) = @_;

    $one = Debian::Dependency->new($one);
    $two = Debian::Dependency->new($two);

    is( $one <=> $two, $expected,
        $expected
        ? (
            ( $expected == -1 )
            ? "$one is less than $two"
            : "$one is greater than $two"
        )
        : "$one and $two are equal"
    );
}

comp( 'foo', 'bar', 1 );
comp( 'bar', 'foo', -1 );
comp( 'foo', 'foo', 0 );
comp( 'foo', 'foo (>= 2)', -1 );
comp( 'foo (>= 2)', 'foo', 1 );
comp( 'foo (<< 2)', 'foo (<= 1)', 1 );
comp( 'foo (<< 1)', 'foo (<= 2)', -1 );

comp( 'foo (<< 2)', 'foo (<< 2)', 0 );
comp( 'foo (<< 2)', 'foo (<= 2)', -1 );
comp( 'foo (<< 2)', 'foo (= 2)', -1 );
comp( 'foo (<< 2)', 'foo (>= 2)', -1 );
comp( 'foo (<< 2)', 'foo (>> 2)', -1 );

comp( 'foo (<= 2)', 'foo (<< 2)', 1 );
comp( 'foo (<= 2)', 'foo (<= 2)', 0 );
comp( 'foo (<= 2)', 'foo (= 2)', -1 );
comp( 'foo (<= 2)', 'foo (>= 2)', -1 );
comp( 'foo (<= 2)', 'foo (>> 2)', -1 );

comp( 'foo (= 2)', 'foo (<< 2)', 1 );
comp( 'foo (= 2)', 'foo (<= 2)', 1 );
comp( 'foo (= 2)', 'foo (= 2)', 0 );
comp( 'foo (= 2)', 'foo (>= 2)', -1 );
comp( 'foo (= 2)', 'foo (>> 2)', -1 );

comp( 'foo (>= 2)', 'foo (<< 2)', 1 );
comp( 'foo (>= 2)', 'foo (<= 2)', 1 );
comp( 'foo (>= 2)', 'foo (= 2)',  1 );
comp( 'foo (>= 2)', 'foo (>= 2)', 0 );
comp( 'foo (>= 2)', 'foo (>> 2)', -1 );

comp( 'foo (>> 2)', 'foo (<< 2)', 1 );
comp( 'foo (>> 2)', 'foo (<= 2)', 1 );
comp( 'foo (>> 2)', 'foo (= 2)',  1 );
comp( 'foo (>> 2)', 'foo (>= 2)', 1 );
comp( 'foo (>> 2)', 'foo (>> 2)', 0 );

comp( 'foo|bar', 'bar|foo', 1 );
comp( 'bar|foo', 'foo|bar', -1 );
comp( 'bar|foo', 'bar|baz', 1 );
comp( 'foo|bar', 'foo|bar', 0 );
comp( 'foo|bar', 'foo', 1 );
comp( 'foo', 'foo|bar', -1 );

done_testing();
