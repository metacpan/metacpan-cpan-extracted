#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;

use Fixture();
use Dist::Conformance::Check::ClaudeSettings();
use Dist::Conformance::Schema();
use Dist::Conformance::Snapshot::Directory();

my %CONFIG = ( file => '.claude/settings.json', plugins => [qw{one@market two@market}] );
my $FILE   = '.claude/settings.json';

sub settings (%config)          { return Fixture::make_check( Dist::Conformance::Check::ClaudeSettings::, { %CONFIG, %config } ) }
sub check_of ( $root, %config ) { return [ settings(%config)->check( Dist::Conformance::Snapshot::Directory->new( root => $root ) ) ] }

subtest check => sub {
    is( check_of( Fixture::checkout() ),                                                                       [ 'fail', '.claude/settings.json is missing' ],       'a missing file fails by default' );
    is( check_of( Fixture::checkout(), missing => 'info' ),                                                    [ 'info', '.claude/settings.json is missing' ],       'or is info if the flavor says so' );
    is( check_of( Fixture::checkout( $FILE => '{' ), missing => 'info' ),                                      [ 'fail', match(qr/does\ not\ parse\ as\ JSON/) ],    'a file that does not parse fails, whatever missing says' );
    is( check_of( Fixture::checkout( $FILE => '{"enabledPlugins":{"one@market":true,"two@market":false}}' ) ), [ 'fail', 'does not enable two@market' ],             'a plugin set to false is not enabled' );
    is( check_of( Fixture::checkout( $FILE => '{"enabledPlugins":[]}' ) ),                                     [ 'fail', 'does not enable one@market, two@market' ], 'nor is one in a malformed list' );
    is( check_of( Fixture::checkout( $FILE => '{"enabledPlugins":{"one@market":true,"two@market":true}}' ) ),  [ 'pass', 'enables one@market, two@market' ],         'all enabled passes' );
    like( dies { settings( plugins => ['no-market'] ) }, qr/\/plugins\/0:\ String\ does\ not\ match/, 'a plugin is plugin@marketplace' );
};

subtest update => sub {
    my $root   = Fixture::checkout();
    my $update = Fixture::run_update( settings( missing => 'info' ), $root );
    is( $update->changes,                                                                         [ { action => 'create', path => $FILE } ],                          'a missing file is written, even when its absence is info' );
    is( Dist::Conformance::Schema::parse_json( $root->child( split m{/}, $FILE )->slurp, $FILE ), { enabledPlugins => { 'one@market' => T(), 'two@market' => T() } }, 'enabling the plugins' );

    my $mine = Fixture::checkout( $FILE => '{"permissions":{"allow":["Read"]},"enabledPlugins":{"one@market":true,"other@x":false}}' );
    is( Fixture::run_update( settings(), $mine )->changes, [ { action => 'replace', path => $FILE } ], 'a file that lacks a plugin is rewritten' );
    is(
        Dist::Conformance::Schema::parse_json( $mine->child( split m{/}, $FILE )->slurp, $FILE ),
        { permissions => { allow => ['Read'] }, enabledPlugins => { 'one@market' => T(), 'two@market' => T(), 'other@x' => F() } },
        'keeping every other key'
    );
    is( Fixture::run_update( settings(), $mine )->changes, [], 'and then has nothing to do' );

    my $odd = Fixture::checkout( $FILE => '{"keep":1,"enabledPlugins":["one@market"]}' );
    Fixture::run_update( settings(), $odd );
    is( Dist::Conformance::Schema::parse_json( $odd->child( split m{/}, $FILE )->slurp, $FILE ), { keep => 1, enabledPlugins => { 'one@market' => T(), 'two@market' => T() } }, 'a malformed enabledPlugins is replaced, and the rest kept' );

    my $broken = Fixture::checkout( $FILE => '{' );
    my $before = Fixture::tree_of($broken);
    my $left   = Fixture::run_update( settings(), $broken );
    is( $left->changes,            [],                                                              'a file that does not parse is not touched' );
    is( Fixture::tree_of($broken), $before,                                                         'at all' );
    is( $left->manual,             [ match(qr/does\ not\ parse\ as\ JSON.*:\ fix\ it\ by\ hand/) ], 'and a person is told' );
};

subtest 'update: a dry run' => sub {
    my $root   = Fixture::checkout();
    my $before = Fixture::tree_of($root);
    is( Fixture::run_update( settings(), $root, 1 )->changes, [ { action => 'create', path => $FILE } ], 'says what it would write' );
    is( Fixture::tree_of($root),                              $before,                                   'and changes nothing on disk' );
};

done_testing;
