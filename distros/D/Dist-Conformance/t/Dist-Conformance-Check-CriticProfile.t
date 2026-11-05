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

# The policies of the fixture template t/data/standards/templates/perlcriticrc, which turns one more off.
my $CURRENT = "severity = 1\n[RegularExpressions::RequireDefault]\nstrict = 1\n[Variables::ProhibitReusedNames]\n";
my $OLD     = "# Troglodyne perlcritic policy\n[Mine]\n";
my %CONFIG  = ( file => '.perlcriticrc', template => 'templates/perlcriticrc' );

sub profile       (%config)          { return Fixture::make_check( Dist::Conformance::Check::CriticProfile::, { %CONFIG, %config } ) }
sub check_of      ( $root, %config ) { return [ profile(%config)->check( Dist::Conformance::Snapshot::Directory->new( root => $root ) ) ] }
sub checkout_with ($text)            { return Fixture::checkout( '.perlcriticrc' => $text ) }

subtest policies => sub {
    my $policies = Dist::Conformance::Check::CriticProfile::policies( "only = 1\n# [Commented::Out]\n[Perl::Critic::Policy::A::B]\nk = v\n[-C::D]\n[ E::F ]\n", 'the profile' );
    is( $policies,                                                               { 'A::B' => 'enabled', 'C::D' => 'disabled', 'E::F' => 'enabled' }, 'each section, by its short name, enabled or disabled; no global key and no comment' );
    is( Dist::Conformance::Check::CriticProfile::policies( q{}, 'the profile' ), {},                                                                 'an empty profile has none' );
    like( dies { Dist::Conformance::Check::CriticProfile::policies( "junk\n", 'the profile' ) }, qr/\Athe\ profile\ does\ not\ parse\ .+\ line\ 1/, 'text that Perl::Critic would refuse dies, naming the file' );
};

subtest missing_policies => sub {
    is( [ profile()->missing_policies($CURRENT) ],                                                                    [],                                                                      'none, when the profile enables every policy that the template enables' );
    is( [ profile()->missing_policies("[Variables::ProhibitReusedNames]\n") ],                                        ['RegularExpressions::RequireDefault'],                                  'the one that it does not' );
    is( [ profile()->missing_policies("[-RegularExpressions::RequireDefault]\n[Variables::ProhibitReusedNames]\n") ], [],                                                                      'a policy turned off on purpose is not missing' );
    is( [ profile()->missing_policies(q{}) ],                                                                         [qw{RegularExpressions::RequireDefault Variables::ProhibitReusedNames}], 'in order, and never one that the template turns off' );
};

subtest check => sub {
    is( check_of( Fixture::checkout() ),     [ 'fail', '.perlcriticrc is missing' ],                   'a missing profile fails' );
    is( check_of( checkout_with($CURRENT) ), [ 'pass', 'has every policy of templates/perlcriticrc' ], 'a profile with every policy passes, with no header at all' );
    is(
        check_of( checkout_with("[RegularExpressions::RequireDefault]\n[Variables::ProhibitReusedNames]\nallow = \$self\n[Mine]\n") ),
        [ 'pass', 'has every policy of templates/perlcriticrc' ], 'parameters of its own, and policies of its own, are its business'
    );
    is(
        check_of( checkout_with("# Troglodyne perlcritic policy, for a distribution that declares use 5.040 or\n[Variables::ProhibitReusedNames]\n") ),
        [ 'fail', 'lacks the policy RegularExpressions::RequireDefault of templates/perlcriticrc' ], 'the current header does not make a profile current'
    );
    is( check_of( checkout_with($OLD) ), [ 'fail', 'lacks the policies RegularExpressions::RequireDefault, Variables::ProhibitReusedNames of templates/perlcriticrc' ], 'an older profile names every policy that it lacks' );
    is(
        check_of( checkout_with($CURRENT), template => 'templates/perlcriticrc.compat' ),
        [ 'fail', 'lacks the policy TestingAndDebugging::RequireUseStrict of templates/perlcriticrc.compat' ], 'the strict profile lacks what the compat flavor adds'
    );
    is( check_of( checkout_with("junk\n") ),                                             [ 'fail', '.perlcriticrc does not parse as a perlcritic profile: Syntax error at line 1: \'junk\'' ], 'a profile that does not parse fails' );
    is( check_of( checkout_with($CURRENT), header => '# Other', outdated => ['# Old'] ), [ 'pass', 'has every policy of templates/perlcriticrc' ],                                             'the deprecated header and outdated still load, and decide nothing' );
};

subtest update => sub {
    my $root   = Fixture::checkout();
    my $update = Fixture::run_update( profile(), $root );
    is( $update->changes, [ { action => 'create', path => '.perlcriticrc' } ],      'a missing profile is written' );
    is( check_of($root),  [ 'pass', 'has every policy of templates/perlcriticrc' ], 'from the template' );

    my $old    = checkout_with($OLD);
    my $before = Fixture::tree_of($old);
    my $kept   = Fixture::run_update( profile(), $old );
    is( $kept->changes,         [],      'a profile that lacks policies is not replaced by default' );
    is( Fixture::tree_of($old), $before, 'so its own changes stay' );
    is(
        $kept->manual,
        ['.perlcriticrc lacks the policies RegularExpressions::RequireDefault, Variables::ProhibitReusedNames of templates/perlcriticrc: add each one to it by hand, or add it as [-Name] to turn it off on purpose, or set replace: true to overwrite it'],
        'and a person is told which policies to add'
    );

    my $replaced = Fixture::run_update( profile( replace => 1 ), $old );
    is( $replaced->changes, [ { action => 'replace', path => '.perlcriticrc' } ],     'with replace, it is replaced' );
    is( check_of($old),     [ 'pass', 'has every policy of templates/perlcriticrc' ], 'and then passes' );

    is( Fixture::run_update( profile(), checkout_with($CURRENT) )->changes, [], 'a current profile is left alone' );
    is(
        Fixture::run_update( profile(), checkout_with("junk\n") )->manual,
        ['.perlcriticrc does not parse as a perlcritic profile: Syntax error at line 1: \'junk\': fix it by hand, or set replace: true to overwrite it'],
        'a profile that does not parse is left for a person'
    );
};

subtest 'update: a dry run' => sub {
    my $root   = checkout_with($OLD);
    my $before = Fixture::tree_of($root);
    my $update = Fixture::run_update( profile( replace => 1 ), $root, 1 );
    is( $update->changes,        [ { action => 'replace', path => '.perlcriticrc' } ], 'says what it would replace' );
    is( Fixture::tree_of($root), $before,                                              'and changes nothing on disk' );
};

done_testing;
