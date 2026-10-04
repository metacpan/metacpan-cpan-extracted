#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);

use lib 'lib';

use Developer::Dashboard::EnvInclude;
use Developer::Dashboard::EnvLoader;

my $EI = 'Developer::Dashboard::EnvInclude';

# Warnings are fatal in this repository: collect any and assert none escaped.
my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0]; return; };

# Hermetic runtime rooted at a temp home; config layers resolve from the cwd,
# so we chdir into the temp home before building any registry.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

sub write_file {
    my ( $path, $content ) = @_;
    make_path( File::Spec->catdir( ( File::Spec->splitpath($path) )[ 0, 1 ] ) );
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print $fh $content;
    close $fh;
    return $path;
}

my $skills_root = File::Spec->catdir( $home, '.developer-dashboard', 'skills' );

# --- _namespace_prefix -------------------------------------------------------
is( $EI->_namespace_prefix('foo'),     'FOO',     '_namespace_prefix: single segment' );
is( $EI->_namespace_prefix('foo.bar'), 'FOO_BAR', '_namespace_prefix: two segments join with a single underscore' );
is(
    $EI->_namespace_prefix('foo.bar.baz'),
    'FOO_BAR_BAZ',
    '_namespace_prefix: three segments'
);
is(
    $EI->_namespace_prefix('foo-thing.bar'),
    'FOO_THING_BAR',
    '_namespace_prefix: non-alphanumeric characters inside a segment collapse to a single underscore'
);

# --- include: single skill, both .env and .env.pl ---------------------------
{
    local %ENV = %ENV;
    my $bar_dir = File::Spec->catdir( $skills_root, 'foo', 'skills', 'bar' );
    write_file( File::Spec->catfile( $bar_dir, '.env' ),    "BOB=1\n" );
    write_file( File::Spec->catfile( $bar_dir, '.env.pl' ), "\$ENV{FROMPL} = 2;\n1;\n" );

    my $loaded = $EI->include('foo.bar');
    is( ref($loaded), 'ARRAY', 'include returns an array reference of loaded files' );
    is( scalar(@$loaded), 2, 'include loaded both the .env and the .env.pl file' );
    is( $ENV{FOO_BAR__BOB},    '1', 'include: plain .env value namespaced as FOO_BAR__BOB' );
    is( $ENV{FOO_BAR__FROMPL}, '2', 'include: .env.pl-set value namespaced as FOO_BAR__FROMPL' );
    ok( !exists $ENV{BOB},    'include: the un-namespaced key is never set directly (.env side)' );
    ok( !exists $ENV{FROMPL}, 'include: the un-namespaced key is never set directly (.env.pl side)' );
}

# --- include: nonexistent skill is silently a no-op -------------------------
{
    local %ENV = %ENV;
    my $loaded = $EI->include('does.not.exist');
    is_deeply( $loaded, [], 'include: an unresolvable skill path loads nothing and does not die' );
}

# --- include: a dotted spec whose FIRST segment exists but whose SECOND does
# not resolves to nothing for that layer, without dying -----------------------
{
    local %ENV = %ENV;
    my $solo_dir = File::Spec->catdir( $skills_root, 'solo' );
    write_file( File::Spec->catfile( $solo_dir, '.env' ), "X=1\n" );    # solo exists, solo/skills/missing does not
    my $loaded = $EI->include('solo.missing');
    is_deeply( $loaded, [], 'include: an existing top-level skill with a nonexistent nested segment resolves to nothing' );
    ok( !exists $ENV{X}, 'include: the existing top-level skill\'s own vars are not pulled in for a mismatched nested spec' );
}

# --- include: a spec that strips to no segments at all (e.g. bare ".*")
# resolves to nothing rather than dying ---------------------------------------
{
    local %ENV = %ENV;
    my $loaded = $EI->include('.*');
    is_deeply( $loaded, [], 'include: a spec with no real segments after stripping ".*" loads nothing' );
}

# --- _valid_segment: defense-in-depth against path traversal/absolute paths -
is( $EI->_valid_segment('foo'), 1, '_valid_segment: an ordinary skill name is valid' );
for my $case ( [ '.', 'a lone dot' ], [ '..', 'a lone double-dot' ], [ 'a/b', 'an embedded forward slash' ],
    [ 'a\\b', 'an embedded backslash' ], [ '/', 'a bare slash' ] )
{
    my ( $bad, $label ) = @$case;
    is( $EI->_valid_segment($bad), 0, "_valid_segment: rejects $label" );
}
is( $EI->_valid_segment("a\x00b"), 0, '_valid_segment: rejects an embedded NUL byte' );
is( $EI->_valid_segment(undef), 0, '_valid_segment: rejects undef' );
is( $EI->_valid_segment(''),    0, '_valid_segment: rejects the empty string' );

# --- include: a spec that survives dot-splitting as a bare "/" segment (from
# a payload like "../..") is rejected outright, never treated as a path -------
{
    local %ENV = %ENV;
    my $secret_dir = File::Spec->catdir( $home, '.developer-dashboard', 'PWNED-OUTSIDE-SKILLS' );
    write_file( File::Spec->catfile( $secret_dir, '.env' ), "PWNED=1\n" );
    my $loaded = $EI->include('../..');
    is_deeply( $loaded, [], 'include: a traversal-shaped spec resolving to a bare "/" segment loads nothing' );
    ok( !( grep { /PWNED/ } keys %ENV ), 'include: no PWNED-prefixed key ever appears in the environment' );
}

# --- include: missing spec dies ----------------------------------------------
{
    my $ok = eval { $EI->include(undef); 1 };
    ok( !$ok, 'include: an undef spec dies' );
    like( $@, qr/Missing skill path/, 'include: the die message names the missing spec' );
}
{
    my $ok = eval { $EI->include(''); 1 };
    ok( !$ok, 'include: an empty spec dies' );
}

# --- include: recursive .* pulls in every nested sub-skill ------------------
{
    local %ENV = %ENV;
    my $bar_dir = File::Spec->catdir( $skills_root, 'foo', 'skills', 'bar' );
    my $baz_dir = File::Spec->catdir( $bar_dir, 'skills', 'baz' );
    write_file( File::Spec->catfile( $baz_dir, '.env' ), "QUX=9\n" );

    # A stray plain FILE (not a directory) directly under bar's skills/ dir
    # must be skipped, not treated as a sub-skill.
    write_file( File::Spec->catfile( $bar_dir, 'skills', 'STRAY_FILE' ), "not a skill\n" );

    my $loaded = $EI->include('foo.bar.*');
    ok( scalar(@$loaded) >= 3, 'include recursive: loaded at least foo.bar (.env+.env.pl) and foo.bar.baz (.env)' );
    is( $ENV{FOO_BAR__BOB},     '1', 'include recursive: the top-level skill itself is still included' );
    is( $ENV{FOO_BAR_BAZ__QUX}, '9', 'include recursive: a nested sub-skill is included under its own deeper namespace' );
    ok( !exists $ENV{FOO_BAR_STRAY_FILE__X}, 'include recursive: a stray non-directory entry under skills/ is not treated as a sub-skill' );
}

# --- include: recursive .* with no sub-skills still includes the skill itself
{
    local %ENV = %ENV;
    my $lone_dir = File::Spec->catdir( $skills_root, 'lone' );
    write_file( File::Spec->catfile( $lone_dir, '.env' ), "ALONE=1\n" );
    my $loaded = $EI->include('lone.*');
    is( $ENV{LONE__ALONE}, '1', 'include recursive: a skill with no sub-skills still includes itself' );
}

# --- env->include(...) bareword-method entry point ---------------------------
{
    local %ENV = %ENV;
    require Developer::Dashboard;
    env->include('foo.bar');
    is( $ENV{FOO_BAR__BOB}, '1', 'env->include(...) resolves to the same include behavior as the direct API' );
}

# --- the "# include <...>" comment directive inside a plain .env file --------
{
    local %ENV = %ENV;
    my $consumer_dir = tempdir( CLEANUP => 1 );
    write_file(
        File::Spec->catfile( $consumer_dir, '.env' ),
        "# include <foo.bar>\nLOCAL=hi\n"
    );
    Developer::Dashboard::EnvLoader->_load_env_file( File::Spec->catfile( $consumer_dir, '.env' ) );
    is( $ENV{LOCAL},          'hi', 'the include directive does not disturb ordinary KEY=VALUE lines around it' );
    is( $ENV{FOO_BAR__BOB},   '1',  'the include directive pulls in and namespaces the named skill' );
}

# --- an ordinary "#" comment that is NOT the include directive is still just
# a comment (regression guard against over-matching) --------------------------
{
    local %ENV = %ENV;
    my $consumer_dir = tempdir( CLEANUP => 1 );
    write_file(
        File::Spec->catfile( $consumer_dir, '.env' ),
        "# this is just a comment, not include <anything>\nPLAIN=1\n"
    );
    Developer::Dashboard::EnvLoader->_load_env_file( File::Spec->catfile( $consumer_dir, '.env' ) );
    is( $ENV{PLAIN}, '1', 'a plain comment line is stripped normally and does not trigger an include' );
}

# --- OOP-LAYERS: a deeper layer's value for the same key wins, but a
# shallower layer's OWN key is never dropped ----------------------------------
{
    local %ENV = %ENV;

    # Home layer: foo.bar defines BOB and SHARED=home.
    my $home_bar_dir = File::Spec->catdir( $home, '.developer-dashboard', 'skills', 'foo', 'skills', 'bar' );
    write_file( File::Spec->catfile( $home_bar_dir, '.env' ), "BOB=1\nSHARED=home\n" );

    # A project layer nested under home: its own foo.bar defines BAZ and
    # SHARED=project - a genuinely different, deeper DD-OOP-LAYER root.
    my $project_dir = File::Spec->catdir( $home, 'project' );
    my $project_bar_dir = File::Spec->catdir( $project_dir, '.developer-dashboard', 'skills', 'foo', 'skills', 'bar' );
    write_file( File::Spec->catfile( $project_bar_dir, '.env' ), "BAZ=2\nSHARED=project\n" );

    chdir $project_dir or die "Unable to chdir to $project_dir: $!";
    my $loaded = $EI->include('foo.bar');
    chdir $home or die "Unable to chdir back to $home: $!";

    ok( scalar(@$loaded) >= 2, 'OOP-LAYERS: both the home and project layer .env files were loaded' );
    is( $ENV{FOO_BAR__BOB}, '1', 'OOP-LAYERS: a home-only key survives when a deeper layer also has the skill' );
    is( $ENV{FOO_BAR__BAZ}, '2', 'OOP-LAYERS: a project-only key survives alongside the home layer\'s own key' );
    is( $ENV{FOO_BAR__SHARED}, 'project', 'OOP-LAYERS: the deeper (project) layer wins for a key both layers define' );
}

is( scalar(@warnings), 0, 'no warnings were emitted anywhere in this file' )
  or diag( 'Warnings: ', join( "\n", @warnings ) );

done_testing();

__END__

=pod

=encoding UTF-8

=head1 NAME

201-envinclude-coverage.t - coverage for Developer::Dashboard::EnvInclude

=head1 PURPOSE

Exercises the DD-979 skill env-include feature: the C<# include E<lt>skill.pathE<gt>>
comment directive, the C<env-E<gt>include(...)> programmatic entry point, double-underscore
namespacing, recursive C<.*> sub-skill inclusion, and DD-OOP-LAYERS recursive merge
semantics for included variables.

=head1 WHY IT EXISTS

C<Developer::Dashboard::EnvInclude> is new functionality with no prior coverage; this
file is its dedicated coverage test, hermetic under a temp C<HOME> per this project's
standing coverage-suite convention.

=head1 WHEN TO USE

Run this whenever C<EnvInclude.pm>, the C<# include> directive recognition in
C<EnvLoader.pm>, or the C<env> package in C<Developer/Dashboard.pm> changes.

=head1 HOW TO USE

  PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/201-envinclude-coverage.t

=head1 WHAT USES IT

The project's own coverage gate (C<script/coverage-gate>) and CI.

=head1 EXAMPLES

Example 1:

  Developer::Dashboard::EnvInclude->include('foo.bar');

Loads skill C<foo>'s nested C<bar> sub-skill's env files, namespaced as C<FOO_BAR__*>.

Example 2:

  env->include('foo.bar.*');

Same as above from a C<.env.pl> file, plus every sub-skill nested beneath C<foo.bar>.

=cut
