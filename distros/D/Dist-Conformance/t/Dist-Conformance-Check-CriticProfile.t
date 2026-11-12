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

subtest sections => sub {
    is(
        Dist::Conformance::Check::CriticProfile::sections("only = 1\n# About A::B\n[Perl::Critic::Policy::A::B]\nk = v\n\n# trailing\n; also\n  j = w\n[-C::D]\nx = y\n[ E::F ] ; mine\nlast = 1"),
        { 'A::B' => "[A::B]\nk = v\n  j = w\n", 'E::F' => "[E::F]\nlast = 1\n" },
        'each enabled section by its short name, as Config::Tiny reads it, with its parameters and without the comments, the blank lines and a section that turns a policy off'
    );
};

subtest without_sections => sub {
    my $without = \&Dist::Conformance::Check::CriticProfile::without_sections;
    my $profile = "# Header of the file\nseverity = 1\n[Keep::Me]\nk = v\n\n# Why Old::One was here\n; and more\n[Perl::Critic::Policy::Old::One] ; inline\nmax = 3\n# between\n  min = 1\n\n# About Keep::Too\n[Keep::Too]\n";
    is( $without->( $profile,                                'Old::One' ),            "# Header of the file\nseverity = 1\n[Keep::Me]\nk = v\n\n\n# About Keep::Too\n[Keep::Too]\n", 'the section, its parameters and the comment directly above go; the comment that ends it and the next section stay' );
    is( $without->( $profile,                                'Absent::One' ),         $profile,                                                                                      'a policy that the profile does not have changes nothing' );
    is( $without->( "# Header\n[Old::One]\nx = 1\n[Mine]\n", 'Old::One' ),            "# Header\n[Mine]\n",                                                                          'a comment block that starts the file is its header, and stays' );
    is( $without->( "[A]\n# about A\n[Old::One]\n",          'Old::One' ),            "[A]\n",                                                                                       'a comment between two sections belongs to the one below it' );
    is( $without->( "[-Old::One]\n[Old::One]\nx = 1",        'Old::One' ),            "[-Old::One]\n",                                                                               'a section that turns it off stays, and a last section without a newline goes' );
    is( $without->( "[Old::One]\n[A]\n[Old::Two]\ny = 2\n",  qw{Old::One Old::Two} ), "[A]\n",                                                                                       'each policy of the list' );
};

subtest retired => sub {
    is( [ profile( retired => [qw{Perl::Critic::Policy::Old::One Old::Two}] )->retired ], [qw{Old::One Old::Two}],                       'by the short name, in order' );
    is( [ profile( retired => ['Subroutines::ProhibitSubroutinePrototypes'] )->retired ], ['Subroutines::ProhibitSubroutinePrototypes'], 'a policy that the template turns off can be retired' );
    is(
        dies { profile( retired => [qw{Old::One Variables::ProhibitReusedNames}] )->retired },
        "templates/perlcriticrc enables Variables::ProhibitReusedNames, which retired names too: a policy is either in the template or retired\n",
        'a policy that the template enables cannot be retired'
    );
    like( dies { profile( retired => ['-Old::One'] ) },           qr{/retired/0}, 'a name with the prefix of a section that turns a policy off is refused' );
    like( dies { profile( retired => [qw{Old::One Old::One}] ) }, qr{/retired},   'and a name given twice' );
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
    is( check_of( checkout_with("junk\n") ), [ 'fail', '.perlcriticrc does not parse as a perlcritic profile: Syntax error at line 1: \'junk\'' ], 'a profile that does not parse fails' );
    my %retire = ( retired => [qw{Old::One Old::Two}] );
    is(
        check_of( checkout_with("$CURRENT\[Old::One]\nmax = 3\n[-Old::Two]\n[Mine]\n"), %retire ),
        [ 'fail', 'enables the retired policy Old::One, which conformance update removes' ], 'a retired policy that the profile enables fails, by name; one that it turns off does not'
    );
    is(
        check_of( checkout_with("[Old::Two]\n[Old::One]\n[Variables::ProhibitReusedNames]\n"), %retire ),
        [ 'fail', 'lacks the policy RegularExpressions::RequireDefault of templates/perlcriticrc; enables the retired policies Old::One, Old::Two, which conformance update removes' ],
        'and with a missing policy, both'
    );
    is( check_of( checkout_with("$CURRENT\[Mine]\n"), %retire ), [ 'pass', 'has every policy of templates/perlcriticrc' ], 'a profile without a retired policy passes' );
    like( dies { profile( retired => ['Variables::ProhibitReusedNames'] )->check( Dist::Conformance::Snapshot::Directory->new( root => checkout_with($CURRENT) ) ) }, qr/which\ retired\ names\ too/, 'a template that enables a retired policy dies' );
    is( check_of( checkout_with($CURRENT), header => '# Other', outdated => ['# Old'] ), [ 'pass', 'has every policy of templates/perlcriticrc' ], 'the deprecated header and outdated still load, and decide nothing' );
};

subtest update => sub {
    my $root   = Fixture::checkout();
    my $update = Fixture::run_update( profile(), $root );
    is( $update->changes, [ { action => 'create', path => '.perlcriticrc' } ],      'a missing profile is written' );
    is( check_of($root),  [ 'pass', 'has every policy of templates/perlcriticrc' ], 'from the template' );

    my $old  = checkout_with($OLD);
    my $kept = Fixture::run_update( profile(), $old );
    is( $kept->changes,                                  [ { action => 'replace', path => '.perlcriticrc' } ],                                        'a profile that lacks policies is not replaced by default, but appended to' );
    is( $kept->manual,                                   [],                                                                                          'with nothing left for a person' );
    is( $old->child('.perlcriticrc')->slurp,             "$OLD\[RegularExpressions::RequireDefault]\nstrict = 1\n[Variables::ProhibitReusedNames]\n", 'each missing policy is added after its own lines, as the template writes it' );
    is( check_of($old),                                  [ 'pass', 'has every policy of templates/perlcriticrc' ],                                    'and then passes' );
    is( Fixture::run_update( profile(), $old )->changes, [],                                                                                          'so a second update has nothing to do' );

    my $own      = "severity = 3\n[Variables::ProhibitReusedNames]\nallow = \$self\n[-RegularExpressions::RequireDefault]\n[-Mine]";
    my $kept_off = checkout_with($own);
    is( Fixture::run_update( profile(), $kept_off )->changes, [],   'a policy turned off on purpose is not added back' );
    is( $kept_off->child('.perlcriticrc')->slurp,             $own, 'and the profile is left as it was' );

    my $partial = checkout_with("[RegularExpressions::RequireDefault]\nstrict = 0\n# mine\n[-Mine]");
    Fixture::run_update( profile(), $partial );
    is( $partial->child('.perlcriticrc')->slurp, "[RegularExpressions::RequireDefault]\nstrict = 0\n# mine\n[-Mine]\n[Variables::ProhibitReusedNames]\n", 'only the policy that it lacks, after a newline that the file did not end with' );

    my $standards   = Fixture::checkout( 'perlcriticrc' => "[A::B]\nmax = {{MAX}}\n" );
    my $placeholder = Dist::Conformance::Check::CriticProfile->from_config(
        name   => 'CriticProfile',
        config => { %CONFIG, template => 'perlcriticrc' },
        source => Dist::Conformance::Source::Directory->new( directory => "$standards" ),
    );
    my $unfilled = Fixture::run_update( $placeholder, checkout_with($OLD) );
    is( $unfilled->changes, [],                                                                                                                                  'a template with a placeholder that nothing fills is not appended' );
    is( $unfilled->manual,  ['Add the policies A::B of perlcriticrc to .perlcriticrc by hand, or set the variables MAX in .conformance.yml: nothing sets them'], 'and a person is told what it needs' );

    $old = checkout_with($OLD);
    my $replaced = Fixture::run_update( profile( replace => 1 ), $old );
    is( $replaced->changes,                  [ { action => 'replace', path => '.perlcriticrc' } ], 'with replace, it is replaced' );
    is( $old->child('.perlcriticrc')->slurp, Fixture::standards()->file('templates/perlcriticrc'), 'by the template' );

    is( Fixture::run_update( profile(), checkout_with($CURRENT) )->changes, [], 'a current profile is left alone' );
    is(
        Fixture::run_update( profile(), checkout_with("junk\n") )->manual,
        ['.perlcriticrc does not parse as a perlcritic profile: Syntax error at line 1: \'junk\': fix it by hand, or set replace: true to overwrite it'],
        'a profile that does not parse is left for a person'
    );
    is( Fixture::run_update( profile( replace => 1 ), checkout_with("junk\n") )->changes, [ { action => 'replace', path => '.perlcriticrc' } ], 'unless replace says to overwrite it' );
};

subtest 'update: a retired policy' => sub {
    my %retire = ( retired => [qw{Old::One Old::Two}] );
    my $root   = checkout_with("$CURRENT\n# Old::One, because\n[Old::One]\nmax = 3\n\n# mine, on purpose\n[Mine]\nx = 1\n");
    my $update = Fixture::run_update( profile(%retire), $root );
    is( $update->changes,                                        [ { action => 'replace', path => '.perlcriticrc' } ],     'a profile that enables a retired policy is edited' );
    is( $update->manual,                                         [],                                                       'with nothing left for a person' );
    is( $root->child('.perlcriticrc')->slurp,                    "$CURRENT\n\n# mine, on purpose\n[Mine]\nx = 1\n",        'its section, its parameters and its comment go, and a policy of its own stays' );
    is( check_of( $root, %retire ),                              [ 'pass', 'has every policy of templates/perlcriticrc' ], 'and then it passes' );
    is( Fixture::run_update( profile(%retire), $root )->changes, [],                                                       'so a second update has nothing to do' );

    my $both = checkout_with("[Old::Two]\nk = v\n[Variables::ProhibitReusedNames]\n");
    is( Fixture::run_update( profile(%retire), $both )->changes, [ { action => 'replace', path => '.perlcriticrc' } ],                                   'a retired policy and a missing one are one change' );
    is( $both->child('.perlcriticrc')->slurp,                    "[Variables::ProhibitReusedNames]\n[RegularExpressions::RequireDefault]\nstrict = 1\n", 'the one goes and the other is appended' );

    my $own = "$CURRENT\[Mine]\n[-Old::One]\n";
    is( Fixture::run_update( profile(%retire), checkout_with($own) )->changes, [], 'a profile without a retired policy is left alone' );

    my $placeholder_standards = Fixture::checkout( 'perlcriticrc' => "[A::B]\nmax = {{MAX}}\n" );
    my $placeholder           = Dist::Conformance::Check::CriticProfile->from_config(
        name   => 'CriticProfile',
        config => { %CONFIG, template => 'perlcriticrc', %retire },
        source => Dist::Conformance::Source::Directory->new( directory => "$placeholder_standards" ),
    );
    my $unfilled_root = checkout_with("[Old::One]\n");
    my $unfilled      = Fixture::run_update( $placeholder, $unfilled_root );
    is( $unfilled_root->child('.perlcriticrc')->slurp, q{}, 'a template with a placeholder still lets the retired policy go' );
    is( scalar @{ $unfilled->manual },                 1,   'and leaves what it cannot append for a person' );

    like( dies { Fixture::run_update( profile( retired => ['RegularExpressions::RequireDefault'] ), checkout_with($OLD) ) }, qr/which\ retired\ names\ too/, 'a template that enables a retired policy dies, rather than removing it' );

    my $dry    = checkout_with("[Old::One]\n$CURRENT");
    my $before = Fixture::tree_of($dry);
    is( Fixture::run_update( profile(%retire), $dry, 1 )->changes, [ { action => 'replace', path => '.perlcriticrc' } ], 'a dry run says that it would remove it' );
    is( Fixture::tree_of($dry),                                    $before,                                              'and removes nothing' );
};

subtest 'update: a dry run' => sub {
    my $appended = checkout_with($OLD);
    my $as_was   = Fixture::tree_of($appended);
    is( Fixture::run_update( profile(), $appended, 1 )->changes, [ { action => 'replace', path => '.perlcriticrc' } ], 'says that it would append' );
    is( Fixture::tree_of($appended),                             $as_was,                                              'and appends nothing' );

    my $root   = checkout_with($OLD);
    my $before = Fixture::tree_of($root);
    my $update = Fixture::run_update( profile( replace => 1 ), $root, 1 );
    is( $update->changes,        [ { action => 'replace', path => '.perlcriticrc' } ], 'says what it would replace' );
    is( Fixture::tree_of($root), $before,                                              'and changes nothing on disk' );
};

done_testing;
