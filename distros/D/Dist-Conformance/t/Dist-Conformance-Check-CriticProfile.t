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
use Dist::Conformance::Source::Directory();

# The fixture template t/data/standards/templates/perlcriticrc.
my $TEMPLATE = Fixture::standards()->file('templates/perlcriticrc');
my $HEADER   = "# Troglodyne perlcritic policy, for a distribution that declares use 5.040 or\n# later.\n";
my %CONFIG   = ( file => '.perlcriticrc', template => 'templates/perlcriticrc' );

sub profile       (%config)          { return Fixture::make_check( Dist::Conformance::Check::CriticProfile::, { %CONFIG, %config } ) }
sub snapshot      ($root)            { return Dist::Conformance::Snapshot::Directory->new( root => $root ) }
sub check_of      ( $root, %config ) { return [ profile(%config)->check( snapshot($root) ) ] }
sub checkout_with ($text)            { return Fixture::checkout( '.perlcriticrc' => $text ) }

# A check whose template is $text, in standards of its own.
sub with_template ( $text, %config ) {
    my $standards = Fixture::checkout( 'perlcriticrc' => $text );
    return Dist::Conformance::Check::CriticProfile->from_config(
        name   => 'CriticProfile',
        config => { %CONFIG, template => 'perlcriticrc', %config },
        source => Dist::Conformance::Source::Directory->new( directory => "$standards" ),
    );
}

subtest profile_of => sub {
    is(
        Dist::Conformance::Check::CriticProfile::profile_of( "only = 1\n# [Commented::Out]\n[Perl::Critic::Policy::A::B]\nk = v\n[-C::D]\nx = y\n[ E::F ]\n", 'the profile' ),
        { settings => { only => 1 }, policies => { 'A::B' => { off => !!0, parameters => { k => 'v' } }, 'C::D' => { off => !!1, parameters => {} }, 'E::F' => { off => !!0, parameters => {} } } },
        'the settings, and each policy by its short name, whether it is off, and its parameters; none for one that is off'
    );
    like( dies { Dist::Conformance::Check::CriticProfile::profile_of( "junk\n", 'the profile' ) }, qr/\Athe\ profile\ does\ not\ parse\ .+\ line\ 1/, 'text that Perl::Critic would refuse dies, naming the file' );
};

subtest rewrite => sub {
    my $rewrite = \&Dist::Conformance::Check::CriticProfile::rewrite;
    my @body    = ( "a = 1\n", "# about b\n", "b = 2\n", "\n", "# the next one\n" );
    is( [ $rewrite->( \@body, {} ) ],                          \@body,                                                                       'no overlay changes nothing' );
    is( [ $rewrite->( \@body, { b => 3 } ) ],                  [ "a = 1\n", "# about b\n", "b = 3\n", "\n", "# the next one\n" ],               'a key keeps its line, with the new value' );
    is( [ $rewrite->( \@body, { a => undef } ) ],              [ "# about b\n", "b = 2\n", "\n", "# the next one\n" ],                          'undef removes its line' );
    is( [ $rewrite->( \@body, { d => 4, c => 3 } ) ],          [ "a = 1\n", "# about b\n", "b = 2\n", "c = 3\n", "d = 4\n", "\n", "# the next one\n" ], 'a new key goes after the last parameter, sorted, before the comments that end the section' );
    is( [ $rewrite->( [ "# just a comment\n" ], { k => 'v' } ) ], [ "k = v\n", "# just a comment\n" ],                                  'and first when the section has none' );
    is( [ $rewrite->( \@body, { z => undef } ) ],              \@body,                                                                       'and removing a key that is not there changes nothing' );
};

subtest expected => sub {
    is( profile()->expected, $TEMPLATE, 'without overrides, the template' );
    is(
        profile( overrides => { 'Perl::Critic::Policy::RegularExpressions::RequireDefault' => { strict => 0, extra => 'x' } } )->expected,
        "${HEADER}severity = 1\n[RegularExpressions::RequireDefault]\nstrict = 0\nextra = x\n[Variables::ProhibitReusedNames]\n[-Subroutines::ProhibitSubroutinePrototypes]\n",
        'a parameter changes on its line, and a new one follows it'
    );
    is(
        profile( overrides => { 'RegularExpressions::RequireDefault' => { strict => undef } } )->expected,
        "${HEADER}severity = 1\n[RegularExpressions::RequireDefault]\n[Variables::ProhibitReusedNames]\n[-Subroutines::ProhibitSubroutinePrototypes]\n",
        '~ removes a parameter of the template'
    );
    is(
        profile( overrides => { 'RegularExpressions::RequireDefault' => 'off', 'Subroutines::ProhibitSubroutinePrototypes' => {} } )->expected,
        "${HEADER}severity = 1\n[-RegularExpressions::RequireDefault]\n[Variables::ProhibitReusedNames]\n[Subroutines::ProhibitSubroutinePrototypes]\n",
        'off turns a policy of the template off, without its parameters, and a mapping turns on one that it turns off'
    );
    is(
        profile( overrides => { 'Z::Mine' => { max => 3 }, 'A::Mine' => {}, 'Not::Installed' => 'off' }, settings => { severity => 3, theme => 'core' } )->expected,
        "${HEADER}severity = 3\ntheme = core\n[RegularExpressions::RequireDefault]\nstrict = 1\n[Variables::ProhibitReusedNames]\n[-Subroutines::ProhibitSubroutinePrototypes]\n\n# The overrides of .conformance.yml\n[A::Mine]\n[-Not::Installed]\n[Z::Mine]\nmax = 3\n",
        'a policy that the template does not name goes at the end, sorted, and the settings change in place'
    );
    is( profile( overrides => { ProhibitReusedNames => { allow => 'x' } } )->expected, "${HEADER}severity = 1\n[RegularExpressions::RequireDefault]\nstrict = 1\n[Variables::ProhibitReusedNames]\nallow = x\n[-Subroutines::ProhibitSubroutinePrototypes]\n", 'an override by the short name of a policy of the template changes that policy' );
    is( dies { profile( overrides => { ProhibitReusedNames => 'off', 'Variables::ProhibitReusedNames' => {} } )->expected }, "overrides names the policy Variables::ProhibitReusedNames twice\n", 'so its short and its full name are one policy twice' );
    is( with_template( "[A::B]\nk = v" )->expected, "[A::B]\nk = v\n", 'a template without a newline at its end gets one' );
    is( dies { with_template( "[A::B]\nmax = {{MAX}}\n" )->expected }, "perlcriticrc needs the variables MAX in .conformance.yml: nothing sets them\n", 'a placeholder that nothing fills dies, naming it' );
    is( dies { profile( overrides => { '-A::B' => 'off' } )->expected },               "overrides names -A::B, which is not the name of a policy\n", 'an override named as a section that turns a policy off is refused' );
    is( dies { profile( overrides => { 'A::B' => 'off', 'Perl::Critic::Policy::A::B' => {} } )->expected }, "overrides names the policy A::B twice\n", 'and so is one policy named twice' );
    my $yaml = Dist::Conformance::Schema::parse_yaml( "Mine:\n  max: 30\n  name: x\n  gone: ~\nOther: off\n", 'the overrides' );
    like( profile( overrides => $yaml )->expected, qr/^\[Mine\]\nmax\ =\ 30\nname\ =\ x\n\[-Other\]\n/m, 'overrides as YAML gives them: a number, a string, ~ and off' );
    like( dies { profile( overrides => { 'A::B' => 'on' } ) },                        qr{/overrides/A::B},                                          'an override is off or a mapping' );
    like( dies { profile( overrides => { 'A::B' => { k => [1] } } ) },                qr{/overrides/A::B},                                          'and a parameter is a string or a number' );
};

subtest differences => sub {
    my $differences = \&Dist::Conformance::Check::CriticProfile::differences;
    my $of          = sub ($text) { Dist::Conformance::Check::CriticProfile::profile_of( $text, 'x' ) };
    my $want        = $of->("severity = 1\n[A]\nk = v\n[B]\n[-C]\n[D]\n");
    is( [ $differences->( $of->("# other\nseverity=1\n[D]\n[-C]\n[B]\n[A]\nk=v\n"), $want ) ], [], 'none for a profile that Perl::Critic reads the same, whatever the order, spacing and comments' );
    is(
        [ $differences->( $of->("severity = 3\n[A]\nk = w\n[C]\n[-D]\n[E]\n[F]\n"), $want ) ],
        [ 'lacks the policy B', 'names the policies E, F, which neither the template nor the overrides name', 'enables the policy C', 'turns off the policy D', 'sets other parameters for the policy A', 'sets other global settings' ],
        'each kind of difference, by name'
    );
};

subtest check => sub {
    is( check_of( Fixture::checkout() ),       [ 'fail', '.perlcriticrc is missing' ],                         'a missing profile fails' );
    is( check_of( checkout_with($TEMPLATE) ), [ 'pass', 'is templates/perlcriticrc with the overrides' ], 'the template passes' );
    is(
        check_of( checkout_with("severity=1\n[Variables::ProhibitReusedNames]\n[RegularExpressions::RequireDefault]\nstrict=1\n[-Subroutines::ProhibitSubroutinePrototypes]\n") ),
        [ 'info', 'differs from templates/perlcriticrc with the overrides only in comments and layout, which conformance update rewrites' ],
        'a profile that Perl::Critic reads as the template, written otherwise, is only worth knowing'
    );
    is(
        check_of( checkout_with("$TEMPLATE\[Mine]\n") ),
        [ 'fail', 'names the policy Mine, which neither the template nor the overrides name, which conformance update corrects' ],
        'a policy that nothing declares fails'
    );
    my $mine = profile( overrides => { Mine => {} } )->expected;
    is( check_of( checkout_with($mine), overrides => { Mine => {} } ), [ 'pass', 'is templates/perlcriticrc with the overrides' ], 'unless an override declares it' );
    is(
        check_of( checkout_with("[Variables::ProhibitReusedNames]\n[RegularExpressions::RequireDefault]\nstrict = 0\n") ),
        [ 'fail', 'lacks the policy Subroutines::ProhibitSubroutinePrototypes; sets other parameters for the policy RegularExpressions::RequireDefault; sets other global settings, which conformance update corrects' ],
        'a policy that it lacks, a parameter, and a setting'
    );
    is( check_of( checkout_with("junk\n") ), [ 'fail', '.perlcriticrc does not parse as a perlcritic profile: Syntax error at line 1: \'junk\', and conformance update replaces it' ], 'a profile that does not parse fails' );
    is( check_of( checkout_with($TEMPLATE), replace => 1, retired => ['Old::One'], header => '# Other', outdated => ['# Old'] ), [ 'pass', 'is templates/perlcriticrc with the overrides' ], 'the deprecated keys still load, and decide nothing' );
};

subtest update => sub {
    my $root   = Fixture::checkout();
    my $update = Fixture::run_update( profile(), $root );
    is( $update->changes,                     [ { action => 'create', path => '.perlcriticrc' } ], 'a missing profile is written' );
    is( $root->child('.perlcriticrc')->slurp, $TEMPLATE,                                         'from the template' );

    my %over = ( overrides => { 'RegularExpressions::RequireDefault' => { strict => 0 }, Mine => 'off' } );
    my $old  = checkout_with("# mine\n[Old::One]\n[RegularExpressions::RequireDefault]\nstrict = 1\n");
    is( Fixture::run_update( profile(%over), $old )->changes, [ { action => 'replace', path => '.perlcriticrc' } ], 'a profile that differs is replaced' );
    is( $old->child('.perlcriticrc')->slurp,                  profile(%over)->expected,                             'by the template with the overrides' );
    is( check_of( $old, %over ),                              [ 'pass', 'is templates/perlcriticrc with the overrides' ], 'and then passes' );
    is( Fixture::run_update( profile(%over), $old )->changes, [],                                                   'so a second update has nothing to do' );

    my $layout = checkout_with("severity=1\n[Variables::ProhibitReusedNames]\n[RegularExpressions::RequireDefault]\nstrict=1\n[-Subroutines::ProhibitSubroutinePrototypes]\n");
    is( Fixture::run_update( profile(), $layout )->changes, [ { action => 'replace', path => '.perlcriticrc' } ], 'a profile that differs only in layout is rewritten too' );
    is( Fixture::run_update( profile(), checkout_with("junk\n") )->changes, [ { action => 'replace', path => '.perlcriticrc' } ], 'and so is one that does not parse' );

    my $unfilled = Fixture::run_update( with_template("[A::B]\nmax = {{MAX}}\n"), checkout_with($TEMPLATE) );
    is( $unfilled->changes, [], 'a template with a placeholder that nothing fills is not written' );
    is( $unfilled->manual,  ['perlcriticrc needs the variables MAX in .conformance.yml: nothing sets them: CriticProfile cannot write .perlcriticrc'], 'and a person is told what it needs' );

    my $dry    = checkout_with("[Old::One]\n");
    my $before = Fixture::tree_of($dry);
    is( Fixture::run_update( profile(), $dry, 1 )->changes, [ { action => 'replace', path => '.perlcriticrc' } ], 'a dry run says what it would replace' );
    is( Fixture::tree_of($dry),                             $before,                                              'and changes nothing on disk' );
};

subtest full_name => sub {
    my $full_name = \&Dist::Conformance::Check::CriticProfile::full_name;
    my %policies  = map { $_ => 1 } qw{Plicease::ProhibitLeadingZeros A::Twice B::Twice Exact};
    is( $full_name->( 'ProhibitLeadingZeros', \%policies ), 'Plicease::ProhibitLeadingZeros', 'the one name that ends with it' );
    is( $full_name->( 'Exact',                \%policies ), 'Exact',                          'a name that is there is itself' );
    is( $full_name->( 'Twice',                \%policies ), 'Twice',                          'and so is one that two names end with' );
    is( $full_name->( 'LeadingZeros',         \%policies ), 'LeadingZeros',                   'and one that ends only part of a name' );
};

subtest adopt => sub {
    is( profile()->adopt( snapshot( Fixture::checkout() ) ),        undef, 'nothing for a missing profile' );
    is( profile()->adopt( snapshot( checkout_with($TEMPLATE) ) ),   undef, 'nor for the template' );
    my $text = "severity = 3\n[RegularExpressions::RequireDefault]\nextra = x\n[Subroutines::ProhibitSubroutinePrototypes]\nmax = 2\n[Mine]\nk = v\n[-Off::Mine]\n[-Subroutines::ProhibitSubroutinePrototypes2]\n";
    my $root    = checkout_with($text);
    my $adopted = profile()->adopt( snapshot($root) );
    is(
        $adopted,
        {
            settings  => { severity => 3 },
            overrides => {
                'RegularExpressions::RequireDefault'         => { strict => undef, extra => 'x' },
                'Subroutines::ProhibitSubroutinePrototypes'  => { max    => 2 },
                'Mine'                                       => { k      => 'v' },
                'Off::Mine'                                  => 'off',
                'Subroutines::ProhibitSubroutinePrototypes2' => 'off',
            },
        },
        'each departure: a changed and a removed parameter, a policy that the template turns off, one of its own, one turned off, and a setting; not the policy that it lacks'
    );
    my $short = profile()->adopt( snapshot( checkout_with("[ProhibitReusedNames]\nallow = \$self\n") ) );
    is( $short->{overrides}, { 'Variables::ProhibitReusedNames' => { allow => '$self' } }, 'a policy named by its short name is adopted by the name of the template' );

    my $kept = profile(%$adopted);
    is( [ $kept->check( snapshot($root) ) ], [ 'fail', 'lacks the policy Variables::ProhibitReusedNames, which conformance update corrects' ], 'with what it adopts, the profile differs only by the policy that the template gained' );
    Fixture::run_update( $kept, $root );
    my $after = Dist::Conformance::Check::CriticProfile::profile_of( $root->child('.perlcriticrc')->slurp, 'after' );
    my $was   = Dist::Conformance::Check::CriticProfile::profile_of( $text,                               'before' );
    delete $after->{policies}{'Variables::ProhibitReusedNames'};
    is( $after, $was, 'so the update keeps what Perl::Critic read, and adds that policy' );
};

done_testing;
