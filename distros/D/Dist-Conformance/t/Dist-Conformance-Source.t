#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;
use File::Temp();
use Mojo::File();

use Dist::Conformance::Source();

my $TREE        = Mojo::File->new( File::Temp::tempdir( CLEANUP => 1 ) );
my $CONFORMANCE = $TREE->child(qw{std conformance})->make_path;
$CONFORMANCE->child('base.yml')->spew("name: base\n");
$TREE->child(qw{std templates})->make_path;

package Fake::Source {
    use Mojo::Base 'Dist::Conformance::Source', -signatures;
    sub root ($)     { return $TREE }
    sub describe ($) { return 'the fake' }
}

subtest 'root and describe are abstract' => sub {
    my $bare = Dist::Conformance::Source->new;
    like( dies { $bare->root },     qr/does\ not\ implement\ root/,     'root dies in the base class' );
    like( dies { $bare->describe }, qr/does\ not\ implement\ describe/, 'describe dies in the base class' );
};

subtest base => sub {
    is( Fake::Source->new->base->to_string,                  $TREE->to_string,               'the top of the tree without a path' );
    is( Fake::Source->new( path => 'std' )->base->to_string, $TREE->child('std')->to_string, 'the path below the top with one' );
};

subtest file => sub {
    my $source = Fake::Source->new( path => 'std' );
    is( $source->file('conformance/base.yml'), "name: base\n", 'reads a file below the path' );
    like( dies { $source->file('conformance/none.yml') }, qr/\AThe\ standards\ at\ the\ fake\ have\ no\ /, 'a missing file names the source' );
    like( dies { $source->file('conformance/none.yml') }, qr/have\ no\ conformance\/none[.]yml/,           'and the path' );
    like( dies { $source->file('templates') },            qr/have\ no\ templates/,                         'a directory is not a file' );
    for my $bad ( qw{/bogus/abs ../escape conformance/../../escape}, q{} ) {
        like( dies { $source->file($bad) }, qr/not\ a\ relative\ path/, "'$bad' is refused" );
    }
};

subtest exists_file => sub {
    my $source = Fake::Source->new( path => 'std' );
    ok( $source->exists_file('conformance/base.yml'),  'a file exists' );
    ok( !$source->exists_file('conformance/none.yml'), 'a missing file does not' );
    ok( !$source->exists_file('conformance'),          'a directory is not a file' );
};

done_testing;
