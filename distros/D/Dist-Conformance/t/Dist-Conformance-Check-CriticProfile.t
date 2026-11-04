#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;

use Fixture();
use Dist::Conformance::Check::CriticProfile();
use Dist::Conformance::Snapshot::Directory();

my $STRICT = "# Troglodyne perlcritic policy, for a distribution that declares use 5.040 or\n";
my $COMPAT = "# Troglodyne perlcritic policy, for a distribution that runs on whatever perl is\n";
my %CONFIG = ( file => '.perlcriticrc', template => 'templates/perlcriticrc', outdated => ['# Troglodyne perlcritic policy'] );

sub profile  (%config)          { return Fixture::make_check( Dist::Conformance::Check::CriticProfile::, { %CONFIG, %config } ) }
sub check_of ( $root, %config ) { return [ profile(%config)->check( Dist::Conformance::Snapshot::Directory->new( root => $root ) ) ] }

subtest header => sub {
    is( profile()->header,                     $STRICT =~ s/\n//r, 'the first line of the template' );
    is( profile( header => '# Mine' )->header, '# Mine',           'or the configured one' );
};

subtest check => sub {
    is( check_of( Fixture::checkout() ), [ 'fail', '.perlcriticrc is missing' ], 'a missing profile fails' );
    is( check_of( Fixture::checkout( '.perlcriticrc' => "${STRICT}severity = 1\n" ) ),                            [ 'pass', 'the current profile' ],                                 'the current header passes' );
    is( check_of( Fixture::checkout( '.perlcriticrc' => "# Troglodyne perlcritic policy\n" ) ),                   [ 'fail', 'an outdated profile: # Troglodyne perlcritic policy' ], 'an older header is outdated' );
    is( check_of( Fixture::checkout( '.perlcriticrc' => $COMPAT ) ),                                              [ 'fail', match(qr/\Aan\ outdated\ profile:\ .+whatever\ perl/) ], 'and so is the profile of the other perl' );
    is( check_of( Fixture::checkout( '.perlcriticrc' => $COMPAT ), template => 'templates/perlcriticrc.compat' ), [ 'pass', 'the current profile' ],                                 'which is current in the compat flavor' );
    is( check_of( Fixture::checkout( '.perlcriticrc' => "severity = 3\n" ) ),                                     [ 'fail', 'not a profile of this standard: severity = 3' ],        'a profile of nobody fails' );
    is( check_of( Fixture::checkout( '.perlcriticrc' => q{} ) ),                                                  [ 'fail', 'not a profile of this standard: ' ],                    'and so does an empty one' );
    is( check_of( Fixture::checkout( '.perlcriticrc' => "${STRICT}x\n" ), header => '# Other' ),                  [ 'fail', match(qr/\Aan\ outdated/) ],                             'a configured header replaces the template' );
};

subtest update => sub {
    my $root   = Fixture::checkout();
    my $update = Fixture::run_update( profile(), $root );
    is( $update->changes,                     [ { action => 'create', path => '.perlcriticrc' } ], 'a missing profile is written' );
    is( $root->child('.perlcriticrc')->slurp, "${STRICT}# later.\nseverity = 1\n",                 'from the template' );

    my $old    = Fixture::checkout( '.perlcriticrc' => "# Troglodyne perlcritic policy\n[Mine]\n" );
    my $before = Fixture::tree_of($old);
    my $kept   = Fixture::run_update( profile(), $old );
    is( $kept->changes,         [],                                                                                                                                                                                     'an outdated profile is not replaced by default' );
    is( Fixture::tree_of($old), $before,                                                                                                                                                                                'so its own changes stay' );
    is( $kept->manual,          ['.perlcriticrc is an outdated profile: # Troglodyne perlcritic policy: bring it up to templates/perlcriticrc by hand, keeping its own changes, or set replace: true to overwrite it'], 'and a person is told how' );

    my $replaced = Fixture::run_update( profile( replace => 1 ), $old );
    is( $replaced->changes,                                                                  [ { action => 'replace', path => '.perlcriticrc' } ], 'with replace, it is replaced' );
    is( [ profile()->check( Dist::Conformance::Snapshot::Directory->new( root => $old ) ) ], [ 'pass', 'the current profile' ],                    'and then passes' );

    is( Fixture::run_update( profile(), Fixture::checkout( '.perlcriticrc' => $STRICT ) )->changes, [], 'a current profile is left alone' );
};

subtest 'update: a dry run' => sub {
    my $root   = Fixture::checkout( '.perlcriticrc' => "# Troglodyne perlcritic policy\n" );
    my $before = Fixture::tree_of($root);
    my $update = Fixture::run_update( profile( replace => 1 ), $root, 1 );
    is( $update->changes,        [ { action => 'replace', path => '.perlcriticrc' } ], 'says what it would replace' );
    is( Fixture::tree_of($root), $before,                                              'and changes nothing on disk' );
};

done_testing;
