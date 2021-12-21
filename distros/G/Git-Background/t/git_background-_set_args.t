#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use Scalar::Util qw(blessed);

use Cwd            ();
use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname( Cwd::abs_path __FILE__ ), 'lib' );

use Local::Thing;

use Git::Background;

{
    my $target = {};
    my $args   = {};
    ok( !defined Git::Background::_set_args( $target, $args ), 'returns undef on success' );
    is_deeply( $target, {}, '... changes nothing on no args' );
}

{
    my $target = {};
    my $args   = { dir => '/tmp/abc', fatal => '0 but true', git => 'git2.1.7' };
    ok( !defined Git::Background::_set_args( $target, $args ), 'returns undef on success' );
    is_deeply( $target, { _dir => '/tmp/abc', _fatal => !!1, _git => ['git2.1.7'] }, '... and changes correct values' );
}

{
    my $dir    = Local::Thing->new('hello world');
    my $target = {};
    my $args   = { dir => $dir };
    ok( !defined Git::Background::_set_args( $target, $args ), 'returns undef on success' );
    is_deeply( $target, { _dir => 'hello world' }, '... and stringifies dir object' );
    ok( !defined blessed $target->{_dir}, '... really' );
}

{
    my $target = {};
    my $args   = { git => [qw(/usr/bin/sudo -u nobody git)] };
    ok( !defined Git::Background::_set_args( $target, $args ), 'returns undef on success' );
    is_deeply( $target, { _git => [qw(/usr/bin/sudo -u nobody git)] }, '... works for git array ref' );
}

#
done_testing();

exit 0;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
