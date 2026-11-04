#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;

use Fixture();
use Dist::Conformance::Check::ClaudeMd();
use Dist::Conformance::Snapshot::Directory();

my %CONFIG = ( file => 'CLAUDE.md', template => 'templates/CLAUDE.md', mentions => [qw{perl-slop:reading-perl perl-slop:testing-perl}] );

sub check_of ( $root, %config ) {
    return [ Fixture::make_check( Dist::Conformance::Check::ClaudeMd::, { %CONFIG, %config } )->check( Dist::Conformance::Snapshot::Directory->new( root => $root ) ) ];
}

subtest check => sub {
    is( check_of( Fixture::checkout() ),                                                                                      [ 'fail', 'CLAUDE.md is missing' ],                                                   'a missing file fails' );
    is( check_of( Fixture::checkout( 'CLAUDE.md' => 'perl-slop:reading-perl' ) ),                                             [ 'fail', 'CLAUDE.md does not name perl-slop:testing-perl' ],                         'a file that lacks a mention fails, and names it' );
    is( check_of( Fixture::checkout( 'CLAUDE.md' => 'nothing' ) ),                                                            [ 'fail', 'CLAUDE.md does not name perl-slop:reading-perl, perl-slop:testing-perl' ], 'every mention that it lacks' );
    is( check_of( Fixture::checkout( 'CLAUDE.md' => 'perl-slop:testing-perl, perl-slop:reading-perl' ) ),                     [ 'pass', 'names perl-slop:reading-perl, perl-slop:testing-perl' ],                   'a file that names them all passes' );
    is( check_of( Fixture::checkout( 'CLAUDE.md' => q{} ), mentions => [] ),                                                  [ 'pass', 'CLAUDE.md exists' ],                                                       'with no mentions, an empty file passes' );
    is( check_of( Fixture::checkout( 'AGENTS.md' => 'perl-slop:reading-perl perl-slop:testing-perl' ), file => 'AGENTS.md' ), [ 'pass', match(qr/\Anames/) ],                                                       'the file is configured' );
};

subtest update => sub {
    my $root   = Fixture::checkout();
    my $before = Fixture::tree_of($root);
    my $update = Fixture::run_update( Fixture::make_check( Dist::Conformance::Check::ClaudeMd::, \%CONFIG ), $root );
    is( $update->changes,        [],                                                                                                                   'nothing is written, because the prose cannot be generated' );
    is( Fixture::tree_of($root), $before,                                                                                                              'not even the template' );
    is( $update->manual,         ['CLAUDE.md is missing: write it by hand, starting from templates/CLAUDE.md, because its prose cannot be generated'], 'a person is told, with the template' );

    my $no_template = { %CONFIG, template => undef };
    delete $no_template->{template};
    is( Fixture::run_update( Fixture::make_check( Dist::Conformance::Check::ClaudeMd::, $no_template ), Fixture::checkout( 'CLAUDE.md' => 'x' ) )->manual,                                             [ match(qr/does\ not\ name\ .+:\ write\ it\ by\ hand,\ because/) ], 'without a template too' );
    is( Fixture::run_update( Fixture::make_check( Dist::Conformance::Check::ClaudeMd::, \%CONFIG ),     Fixture::checkout( 'CLAUDE.md' => 'perl-slop:reading-perl perl-slop:testing-perl' ) )->manual, [],                                                                 'and nothing when it passes' );
};

done_testing;
