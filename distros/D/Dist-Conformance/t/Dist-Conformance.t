#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use File::Temp();
use FindBin();
use FindBin::libs;
use Mojo::File();
use Test::MockModule();

use Fixture();
use Dist::Conformance::Snapshot::Tree();
use Dist::Conformance::Source::Git();
use Dist::Conformance();

my $STANDARDS = "$FindBin::Bin/data/standards";
my $STRICT    = "# Troglodyne perlcritic policy, for a distribution that declares use 5.040 or\n# later.\nseverity = 1\n";

# A checkout whose .conformance.yml names $flavor of the fixture standards, plus %files.
sub repo ( $flavor, $extra = q{}, %files ) {
    return Fixture::checkout( '.conformance.yml' => "flavor: $flavor\nsource: { directory: $STANDARDS }\n$extra", %files );
}

sub statuses ($results) {
    return { map { $_->{check} => $_->{status} } @$results };
}

subtest 'check: an empty repository' => sub {
    my $results = Dist::Conformance->new( root => repo('troglodyne-5.040') )->check;
    is( [ map { $_->{check} } @$results ], [qw{ClaudeMd ClaudeSettings CriticProfile DistFiles GitHooks PerlSlopConfig SystemPackages ToolConfiguration Workflows}], 'every check of the flavor, by name' );
    is(
        statuses($results),
        { ClaudeMd => 'fail', ClaudeSettings => 'info', CriticProfile => 'fail', DistFiles => 'info', GitHooks => 'fail', PerlSlopConfig => 'info', SystemPackages => 'pass', ToolConfiguration => 'fail', Workflows => 'info' },
        'with the statuses that the flavor gives a miss'
    );
    ok( Dist::Conformance::failed($results), 'and it failed' );
};

subtest 'check: the flavor decides' => sub {
    my $compat = Dist::Conformance->new( root => repo( 'troglodyne-compat', q{}, '.perlcriticrc' => $STRICT ) )->check;
    my ($profile) = grep { $_->{check} eq 'CriticProfile' } @$compat;
    is( $profile->{status}, 'fail', 'the strict profile is not current for the compat flavor' );

    my $service = statuses( Dist::Conformance->new( root => repo('troglodyne-service') )->check );
    ok( !exists $service->{DistFiles}, 'a service has no dist files to check' );
    is( $service->{Workflows},      'fail', 'but needs its CI' );
    is( $service->{ClaudeSettings}, 'fail', 'and the Claude settings' );
};

subtest 'check: .conformance.yml' => sub {
    my $results = Dist::Conformance->new( root => repo( 'troglodyne-5.040', "skip: [Workflows, ClaudeMd]\nchecks: { ClaudeSettings: { missing: fail }, GitHooks: { level: info } }\n" ) )->check;
    my %by      = map { $_->{check} => $_ } @$results;
    is( $by{Workflows},              { check => 'Workflows', status => 'skip', detail => 'skipped by .conformance.yml' }, 'a skipped check is reported as skipped' );
    is( $by{ClaudeMd}{status},       'skip',                                                                              'every one of them' );
    is( $by{ClaudeSettings}{status}, 'fail',                                                                              'a setting of the repository overrides the flavor' );
    is( $by{GitHooks}{status},       'info',                                                                              'and level info turns a failure into info' );
    like( $by{GitHooks}{detail}, qr/\Amissing:/, 'keeping its detail' );

    like( dies { Dist::Conformance->new( root => repo( 'troglodyne-5.040', "skip: [Nope]\n" ) )->check },         qr/\/skip\/0:\ names\ a\ check\ that\ the\ flavor/, 'skipping a check that the flavor does not run is an error' );
    like( dies { Dist::Conformance->new( root => repo( 'troglodyne-5.040', "checks: { Nope: {} }\n" ) )->check }, qr/\/checks\/Nope:\ names\ a\ check/,               'and so is configuring one' );
    like(
        dies { Dist::Conformance->new( root => repo( 'troglodyne-5.040', "checks: { GitHooks: { typo: 1 } }\n" ) )->check },
        qr/\Athe\ check\ GitHooks\ of\ the\ flavor\ \S+\ with/,
        'a bad setting names the check, the flavor and the file'
    );
    like( dies { Dist::Conformance->new( root => repo('nowhere') )->check }, qr/There\ is\ no\ flavor\ nowhere/, 'an unknown flavor is an error' );
};

subtest 'check: an unknown check' => sub {
    my $std = Mojo::File->new( File::Temp::tempdir( CLEANUP => 1 ) );
    my $dir = $std->child('conformance')->make_path;
    $dir->child('unknown.yml')->spew("name: unknown\nchecks: { NoSuchCheck: {} }\n");
    $dir->child('notacheck.yml')->spew("name: notacheck\nchecks: { X: { module: 'Dist::Conformance::Schema' } }\n");
    $dir->child('badmodule.yml')->spew("name: badmodule\nchecks: { X: { module: 'a b' } }\n");
    my sub conformance ($flavor) { return Dist::Conformance->new( root => Fixture::checkout( '.conformance.yml' => "flavor: $flavor\nsource: { directory: $std }\n" ) ) }
    like( dies { conformance('unknown')->check },   qr/its\ module\ \S+NoSuchCheck\ does\ not\ load/,         'a check without a module is named' );
    like( dies { conformance('notacheck')->check }, qr/but\ \S+Schema\ is\ not\ a\ Dist::Conformance::Check/, 'a module that is not a check is refused' );
    like( dies { conformance('badmodule')->check }, qr/but\ \S+::a\ b\ is\ not\ the\ name\ of\ a\ module/,    'and so is a name that is not a module' );
};

subtest 'check: a check that dies or misbehaves' => sub {
    my $conformance = Dist::Conformance->new( root => repo('github-ci') );
    my ($workflows) = @{ $conformance->checks };
    my $mock        = Test::MockModule->new( ref $workflows );
    $mock->redefine( check => sub { die "boom\n" } );
    is( $conformance->check, [ { check => 'Workflows', status => 'fail', detail => 'the check died: boom' } ], 'a check that dies fails' );
    $mock->redefine( check => sub { return ( 'great', 'x' ) } );
    is( $conformance->check->[0]{detail}, 'the check returned the status great, which is not pass, fail or info', 'and so does one with a status that is not one of the three' );
};

subtest 'check: a remote snapshot' => sub {
    my %files = (
        '.conformance.yml'         => "flavor: github-ci\nsource: { directory: $STANDARDS }\n",
        '.github/workflows/ci.yml' => 'mine',
    );
    my $snapshot = Dist::Conformance::Snapshot::Tree->new( paths => { map { $_ => Dist::Conformance::Snapshot::blob_sha( $files{$_} ) } keys %files }, fetch => sub ($path) { $files{$path} } );
    is( Dist::Conformance->new( snapshot => $snapshot )->check, [ { check => 'Workflows', status => 'pass', detail => 'all present' } ], 'a tree is checked like a checkout' );
    like( dies { Dist::Conformance->new( snapshot => $snapshot )->update }, qr/needs\ a\ snapshot\ that\ it\ can\ write/, 'and cannot be updated' );
    like( dies { Dist::Conformance->new->check },                           qr/needs\ a\ root\ or\ a\ snapshot/,          'one of them is required' );
};

subtest update => sub {
    my $root        = repo( 'troglodyne-5.040', "variables: { DIST: Foo-Bar, VERSION: '0.001', DATE: 2026-01-01, CPAN_ID: TESTER, AUTHOR_NAME: A. Tester, AUTHOR_EMAIL: tester\@test.test }\n", 'dist.ini' => q{} );
    my $conformance = Dist::Conformance->new( root => $root );
    my $results     = $conformance->update;
    my %by          = map { $_->{check} => $_ } @$results;
    is( [ sort keys %by ],                                   [qw{ClaudeMd ClaudeSettings CriticProfile DistFiles GitHooks PerlSlopConfig SystemPackages ToolConfiguration Workflows}], 'every check ran its update' );
    is( [ map { $_->{path} } @{ $by{DistFiles}{changes} } ], [qw{Changes prereqs.yml weaver.ini}],                                                                                     'a variable of the flavor and of the repository fill a template together' );
    like( $root->child('prereqs.yml')->slurp, qr/perl:\ '5[.]040'/,                    'the flavor sets the floor' );
    like( $root->child('weaver.ini')->slurp,  qr/A[.]\ Tester\ <tester\@test[.]test>/, 'and the repository the author' );
    is( $by{ClaudeMd}{changes},            [], 'CLAUDE.md is not written' );
    is( scalar @{ $by{ClaudeMd}{manual} }, 1,  'but left for a person' );

    my $after = statuses( Dist::Conformance->new( root => $root )->check );
    is( [ grep { $after->{$_} eq 'fail' } sort keys %$after ],                               ['ClaudeMd'], 'after the update only the prose fails' );
    is( [ map { @{ $_->{changes} } } @{ Dist::Conformance->new( root => $root )->update } ], [],           'and a second update changes nothing' );
};

subtest 'update: a dry run' => sub {
    my $root   = repo( 'troglodyne-service', q{}, '.perlcriticrc' => "# Troglodyne perlcritic policy\n" );
    my $before = Fixture::tree_of($root);
    my $plan   = Dist::Conformance->new( root => $root )->update( dry_run => 1 );
    ok( scalar( map { @{ $_->{changes} } } @$plan ) > 5, 'it says what it would change' );
    is( Fixture::tree_of($root), $before, 'and changes nothing on disk, .git included' );
};

subtest 'update: skipped checks and a check that dies' => sub {
    my $root        = repo( 'troglodyne-5.040', "skip: [ToolConfiguration]\n" );
    my $conformance = Dist::Conformance->new( root => $root );
    my $mock        = Test::MockModule->new('Dist::Conformance::Check::Workflows');
    $mock->redefine( update => sub { die "boom\n" } );
    my %by = map { $_->{check} => $_ } @{ $conformance->update };
    ok( !exists $by{ToolConfiguration},  'a skipped check does not update' );
    ok( !-e $root->child('.perltidyrc'), 'so its files are not written' );
    is( $by{Workflows}{manual}, ['The update died: boom'], 'a check whose update dies says so' );
    ok( scalar @{ $by{GitHooks}{changes} }, 'and the others still run' );
};

subtest 'build_source' => sub {
    is( ref Dist::Conformance->new( root => repo('github-ci') )->source, 'Dist::Conformance::Source::Directory', 'a directory' );
    my $relative = Fixture::checkout( '.conformance.yml' => "flavor: github-ci\nsource: { directory: std, path: p }\n" );
    is( Dist::Conformance->new( root => $relative )->source->directory, $relative->child('std')->to_string, 'a relative directory is under the root' );
    my $git    = Fixture::checkout( '.conformance.yml' => "flavor: github-ci\nsource: { git: /bogus/std.git, ref: v1, path: p }\n" );
    my $source = Dist::Conformance->new( root => $git, cache => '/bogus/cache', offline => 1 )->source;
    is( [ ref $source, $source->url, $source->ref, $source->path, $source->cache, $source->offline ], [qw{Dist::Conformance::Source::Git /bogus/std.git v1 p /bogus/cache 1}], 'a git source with the options' );
    my $local = Dist::Conformance->new( root => $git, standards => $STANDARDS )->source;
    is( [ ref $local, $local->directory, $local->path ], [ 'Dist::Conformance::Source::Directory', $STANDARDS, 'p' ], 'standards replace the source, and keep its path' );
};

subtest 'a git source' => sub {
    skip_all 'set RELEASE_TESTING=1 to run git against a bare repository' if !$ENV{RELEASE_TESTING};
    my $work = Mojo::File->new( File::Temp::tempdir( CLEANUP => 1 ) );
    my $bare = $work->child('standards.git');
    my $git  = \&Dist::Conformance::Source::Git::git;
    $git->( qw{init --quiet}, "$work/edit" );
    $git->( '-C', "$work/edit", qw{config user.name Tester} );
    $git->( '-C', "$work/edit", qw{config user.email tester@test.test} );
    Mojo::File->new($STANDARDS)->list_tree->each(
        sub ( $file, $ ) {
            my $to = $work->child( 'edit', 'std', $file->to_rel($STANDARDS)->to_string );
            $to->dirname->make_path;
            $file->copy_to($to);
        }
    );
    $git->( '-C',                     "$work/edit", qw{add -A} );
    $git->( '-C',                     "$work/edit", qw{commit --quiet -m standards} );
    $git->( qw{clone --quiet --bare}, "$work/edit", "$bare" );

    my $root        = Fixture::checkout( '.conformance.yml' => "flavor: github-ci\nsource: { git: $bare, ref: HEAD, path: std }\n" );
    my $conformance = Dist::Conformance->new( root => $root, cache => "$work/cache" );
    is( $conformance->check->[0]{status},                                                                  'fail',                                                         'the flavor is fetched and checked' );
    is( $conformance->update->[0]{changes},                                                                [ { action => 'create', path => '.github/workflows/ci.yml' } ], 'and the update writes from its templates' );
    is( Dist::Conformance->new( root => $root, cache => "$work/cache", offline => 1 )->check->[0]{status}, 'pass',                                                         'and offline reads the cache' );
};

done_testing;
