#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;

use Fixture();
use Dist::Conformance::Check::RefusedIniKeys();
use Dist::Conformance::Snapshot::Directory();

my $REASON = 'overrides the account in the URL of the origin remote';
my %CONFIG = ( file => 'dist.ini', refuse => { GithubMeta => { user => $REASON } } );

my $INI = <<'END';
name = Foo
; the metadata
[GithubMeta]
issues = 1
user = someone ; an old template set it
homepage = https://test.test/

[Run::Test]
user = kept, because this section refuses nothing
END
my $FIXED = $INI =~ s/^user\ =\ someone.*?\n//mr;

sub refusing (%config)          { return Fixture::make_check( Dist::Conformance::Check::RefusedIniKeys::, { %CONFIG, %config } ) }
sub check_of ( $root, %config ) { return [ refusing(%config)->check( Dist::Conformance::Snapshot::Directory->new( root => $root ) ) ] }
sub ini_of   ($root)            { return $root->child('dist.ini')->slurp }

subtest config => sub {
    like( dies { refusing( refuse => {} ) }, qr{/refuse:\ }, 'refuse names at least one plugin' );
    like( dies { refusing( refuse => { GithubMeta => {} } ) },           qr{/refuse/GithubMeta:\ }, 'and each plugin at least one key' );
    like( dies { refusing( refuse => { GithubMeta => [] } ) },           qr{/refuse/GithubMeta:\ }, 'as a mapping' );
    like( dies { refusing( refuse => { A          => { k => q{} } } ) }, qr{/refuse/A/k:\ },        'with a reason' );
    ok( lives { refusing( file => 'conf' ) }, 'a file of any name is read as INI' );
};

subtest refused => sub {
    is(
        [ refusing()->refused($INI) ],
        [ { line => 4, section => 'GithubMeta', key => 'user', reason => $REASON } ],
        'the line, the section, the key and the reason; not the same key in another section'
    );
    is( [ refusing()->refused("[ GithubMeta / Meta ]\n  user=x\n[GithubMetaData]\nuser = y\n") ], [ { line => 1, section => 'GithubMeta / Meta', key => 'user', reason => $REASON } ], 'a plugin with a name of its own, and not another plugin whose name starts the same' );
    is( [ refusing()->refused(";user = x\n[GithubMeta]\n; user = x\nissues = 1 ; user = x\n") ],  [],                                                                                  'never a comment' );
    is( [ refusing()->refused("[GithubMeta] ; the metadata\nuser = x\n") ],                       [ { line => 1, section => 'GithubMeta', key => 'user', reason => $REASON } ],        'a header with a comment after it is still a header' );
    is( [ refusing( refuse => { _ => { user => 'r' } } )->refused("user = x\n[A]\nuser = y\n") ], [ { line => 0, section => '_', key => 'user', reason => 'r' } ],                     'the keys before the first header are in _' );
    like( dies { refusing()->refused("[GithubMeta\n") }, qr/\Adist[.]ini\ does\ not\ parse\ as\ INI/, 'text that does not parse dies' );
};

subtest check => sub {
    is( check_of( Fixture::checkout() ),                       [ 'info', 'there is no dist.ini' ],                              'an absent file is info' );
    is( check_of( Fixture::checkout(), missing => 'fail' ),    [ 'fail', 'there is no dist.ini' ],                              'or what the flavor says' );
    is( check_of( Fixture::checkout( 'dist.ini' => $FIXED ) ), [ 'pass', 'sets no key that the flavor refuses' ],               'a file without a refused key passes' );
    is( check_of( Fixture::checkout( 'dist.ini' => $INI ) ),   [ 'fail', "dist.ini sets user in [GithubMeta], which $REASON" ], 'a refused key fails, with its section and the reason' );
    is(
        check_of( Fixture::checkout( 'dist.ini' => "[GithubMeta]\nuser = a\n[GithubMeta / B]\nuser = b\n" ) ),
        [ 'fail', "dist.ini sets user in [GithubMeta], which $REASON; user in [GithubMeta / B], which $REASON" ],
        'each one is named'
    );
    is( check_of( Fixture::checkout( 'dist.ini' => "[GithubMeta\n" ) ), [ 'fail', match(qr/\Adist[.]ini\ does\ not\ parse\ as\ INI/) ], 'a file that does not parse fails' );
};

subtest update => sub {
    my $root   = Fixture::checkout( 'dist.ini' => $INI );
    my $update = Fixture::run_update( refusing(), $root );
    is( $update->changes,                                  [ { action => 'replace', path => 'dist.ini' } ],   'a file with a refused key is rewritten' );
    is( ini_of($root),                                     $FIXED,                                            'without the line that sets it, and with every other line and comment' );
    is( $update->manual,                                   [],                                                'with nothing left for a person' );
    is( check_of($root),                                   [ 'pass', 'sets no key that the flavor refuses' ], 'so it then passes' );
    is( Fixture::run_update( refusing(), $root )->changes, [],                                                'and a second update has nothing to do' );

    my $both = Fixture::checkout( 'dist.ini' => "[GithubMeta / A]\nuser = a\nuser = b\n[B]\nk = v" );
    Fixture::run_update( refusing(), $both );
    is( ini_of($both), "[GithubMeta / A]\n[B]\nk = v", 'every repeat of the key goes, and a last line without a newline stays as it was' );

    my $broken = Fixture::checkout( 'dist.ini' => "[GithubMeta\nuser = x\n" );
    my $left   = Fixture::run_update( refusing(), $broken );
    is( $left->changes,                                                  [],                                                                      'a file that does not parse is not touched' );
    is( $left->manual,                                                   [ match(qr/\Adist[.]ini\ does\ not\ parse\ .*:\ fix\ it\ by\ hand\z/) ], 'and is left for a person' );
    is( Fixture::run_update( refusing(), Fixture::checkout() )->changes, [],                                                                      'an absent file needs nothing' );
    is( Fixture::run_update( refusing(), Fixture::checkout() )->manual,  [],                                                                      'and nothing of a person' );
};

subtest 'update: a dry run' => sub {
    my $root   = Fixture::checkout( 'dist.ini' => $INI );
    my $before = Fixture::tree_of($root);
    is( Fixture::run_update( refusing(), $root, 1 )->changes, [ { action => 'replace', path => 'dist.ini' } ], 'says what it would rewrite' );
    is( Fixture::tree_of($root),                              $before,                                         'and changes nothing on disk' );
};

done_testing;
