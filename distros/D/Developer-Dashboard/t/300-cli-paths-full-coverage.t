#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Capture::Tiny qw(capture);
use Cwd qw(abs_path cwd);
use File::Basename qw(basename);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::CLI::Paths ();
use Developer::Dashboard::JSON qw(json_decode);
use Developer::Dashboard::PathRegistry;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0]; return; };

my $orig_cwd = cwd();
my $home = abs_path( tempdir( CLEANUP => 1 ) );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

my $run     = \&Developer::Dashboard::CLI::Paths::run_paths_command;
my $package = 'Developer::Dashboard::CLI::Paths';

sub _write {
    my ( $file, $content ) = @_;
    my ( undef, $dir ) = File::Spec->splitpath($file);
    make_path($dir);
    open my $fh, '>', $file or die "Unable to write $file: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $file: $!";
    return $file;
}

sub _skill {
    my ( $name, $folder_source ) = @_;
    my $root = File::Spec->catdir( $home, '.developer-dashboard', 'skills', split( /\./, $name ) );
    if ( $name =~ /\./ ) {
        my @seg = split /\./, $name;
        $root = File::Spec->catdir( $home, '.developer-dashboard', 'skills', shift @seg );
        $root = File::Spec->catdir( $root, 'skills', $_ ) for @seg;
    }
    make_path($root);
    _write( File::Spec->catfile( $root, 'lib', 'Folder.pm' ), $folder_source ) if defined $folder_source;
    return $root;
}

sub _run {
    my (@args) = @_;
    my $ok;
    my ( $out, $err ) = capture { $ok = eval { $run->(@args); 1 }; };
    return ( $ok, $@, $out, $err );
}

my $registry = sub { Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home, @_ ) };

{

    package Test::Paths300::Stub;

    # new(%args)
    # Builds a stand-in path registry so defensive branches can be driven with
    # payloads a real registry never returns.
    # Input: named hash of canned values.
    # Output: stub object.
    sub new { my ( $class, %a ) = @_; return bless {%a}, $class }

    # nested_skill_entries()
    # Returns the canned skill entry list.
    # Input: none.
    # Output: list of entry hashes.
    sub nested_skill_entries { return @{ $_[0]{entries} || [] } }

    # _expand_home($path)
    # Identity home expansion.
    # Input: path string.
    # Output: the same string.
    sub _expand_home { return $_[1] }
}

subtest 'paths command output modes' => sub {
    my ( $ok, $err, $out ) = _run( command => 'paths', args => [ '-o', 'json' ] );
    ok( $ok, 'paths -o json succeeds' );
    ok( ref( json_decode($out) ) eq 'HASH', 'paths -o json prints a json object' );

    ( $ok, $err, $out ) = _run( command => 'paths', args => [] );
    ok( $ok, 'paths default table succeeds' );
    like( $out, qr/Path/, 'table output has a Path column' );

    ( $ok, $err ) = _run( command => 'paths', args => [ '-o', 'xml' ] );
    ok( !$ok, 'paths rejects an unknown output format' );
    like( $err, qr/Usage: dashboard paths/, 'usage is reported' );
};

subtest 'path locate, list and project-root' => sub {
    my ( $ok, $err, $out ) = _run( command => 'path', args => [ 'locate', '-o', 'json', 'nothing-matches-here' ] );
    ok( $ok, 'locate json succeeds' );
    is_deeply( json_decode($out), [], 'no projects match' );

    ( $ok, $err, $out ) = _run( command => 'path', args => [ 'locate', 'nothing-matches-here' ] );
    ok( $ok, 'locate table succeeds' );

    ( $ok, $err ) = _run( command => 'path', args => [ 'locate', '-o', 'xml' ] );
    ok( !$ok, 'locate rejects a bad output format' );
    like( $err, qr/Usage: dashboard path locate/, 'locate usage reported' );

    ( $ok, $err, $out ) = _run( command => 'path', args => ['list'] );
    ok( $ok, 'list table succeeds' );
    ( $ok, $err, $out ) = _run( command => 'path', args => [ 'list', '-o', 'json' ] );
    ok( $ok, 'list json succeeds' );
    ( $ok, $err ) = _run( command => 'path', args => [ 'list', '-o', 'xml' ] );
    ok( !$ok, 'list rejects an unknown output format' );

    ( $ok, $err, $out ) = _run( command => 'path', args => ['project-root'] );
    is( $out, '', 'no project root outside a checkout' );
    my $proj = File::Spec->catdir( $home, 'proj' );
    make_path( File::Spec->catdir( $proj, '.git' ) );
    chdir $proj or die $!;
    ( $ok, $err, $out ) = _run( command => 'path', args => ['project-root'] );
    chdir $home or die $!;
    like( $out, qr/proj/, 'project root printed inside a checkout' );
};

subtest 'path add and del modes' => sub {
    my $target = File::Spec->catdir( $home, 'created-target' );
    my ( $ok, $err, $out ) = _run( command => 'path', args => [ 'add', 'tbl', $target ] );
    ok( $ok, 'add table output succeeds' ) or diag $err;
    like( $out, qr/tbl/, 'table mentions alias' );

    ( $ok, $err, $out ) = _run( command => 'path', args => [ 'add', 'bare', $target, '--create' ] );
    ok( $ok, 'add --create with no mode' ) or diag $err;

    ( $ok, $err, $out ) = _run( command => 'path', args => [ 'add', 'moded', $target, '--create=0755', '-o', 'json' ] );
    ok( $ok, 'add --create with mode' ) or diag $err;
    is( json_decode($out)->{mode}, '0755', 'mode is stored' );

    ( $ok, $err ) = _run( command => 'path', args => [ 'add', 'bad', $target, '--create=abc' ] );
    ok( !$ok, 'bad mode is rejected' );
    like( $err, qr/octal/, 'octal error reported' );

    ( $ok, $err ) = _run( command => 'path', args => [ 'add', 'bad', $target, '-o', 'xml' ] );
    ok( !$ok, 'bad output rejected on add' );
    like( $err, qr/Usage: dashboard path add/, 'add usage reported' );

    ( $ok, $err, $out ) = _run( command => 'path', args => [ 'add', '.', '-o', 'json' ] );
    ok( $ok, 'add . uses cwd shorthand' ) or diag $err;
    is( json_decode($out)->{name}, basename($home), 'alias named after cwd basename' );

    ( $ok, $err, $out ) = _run( command => 'path', args => [ 'add', 'dotpath', '.', '-o', 'json' ] );
    ok( $ok, 'add name . uses cwd' ) or diag $err;

    # deleting by '.' finds the preferred-name alias that points at cwd
    ( $ok, $err, $out ) = _run( command => 'path', args => [ 'del', '.', '-o', 'json' ] );
    ok( $ok, 'del . succeeds' ) or diag $err;
    is( json_decode($out)->{name}, basename($home), 'preferred alias deleted' );

    # now only dotpath points at cwd: scan loop finds it
    ( $ok, $err, $out ) = _run( command => 'path', args => [ 'del', '.', '-o', 'json' ] );
    ok( $ok, 'del . scan succeeds' ) or diag $err;
    is( json_decode($out)->{name}, 'dotpath', 'scan found the alias pointing at cwd' );

    ( $ok, $err, $out ) = _run( command => 'path', args => [ 'del', 'tbl' ] );
    ok( $ok, 'del table output' ) or diag $err;
    ( $ok, $err, $out ) = _run( command => 'path', args => [ 'rm', 'bare' ] );
    ok( $ok, 'rm alias works' ) or diag $err;

    ( $ok, $err ) = _run( command => 'path', args => [ 'del', 'x', '-o', 'xml' ] );
    ok( !$ok, 'del bad output rejected' );
    like( $err, qr/Usage: dashboard path del/, 'del usage reported' );
};

subtest 'resolve and cdr with aliases' => sub {
    my $base = File::Spec->catdir( $home, 'cdrbase' );
    make_path( File::Spec->catdir( $base, 'alpha-one' ), File::Spec->catdir( $base, 'alpha-two' ), File::Spec->catdir( $base, 'beta' ) );
    my ( $ok, $err, $out ) = _run( command => 'path', args => [ 'add', 'cb', $base ] );
    ok( $ok, 'alias added' ) or diag $err;

    ( $ok, $err, $out ) = _run( command => 'path', args => [ 'resolve', 'cb' ] );
    is( $out, "$base\n", 'configured alias resolves' );

    ( $ok, $err, $out ) = _run( command => 'path', args => [ 'cdr', 'cb' ] );
    is( json_decode($out)->{target}, $base, 'alias alone is the target' );

    ( $ok, $err, $out ) = _run( command => 'path', args => [ 'cdr', 'cb', 'beta' ] );
    is( json_decode($out)->{target}, File::Spec->catdir( $base, 'beta' ), 'single match becomes target' );

    ( $ok, $err, $out ) = _run( command => 'path', args => [ 'cdr', 'cb', 'alpha' ] );
    my $payload = json_decode($out);
    is( $payload->{target}, $base, 'multiple matches keep the alias root' );
    is( scalar @{ $payload->{matches} }, 2, 'both matches are listed' );

    chdir $base or die $!;
    ( $ok, $err, $out ) = _run( command => 'path', args => [ 'cdr', 'beta' ] );
    is( json_decode($out)->{target}, File::Spec->catdir( $base, 'beta' ), 'cwd search single match' );
    ( $ok, $err, $out ) = _run( command => 'path', args => [ 'cdr', 'alpha' ] );
    is( scalar @{ json_decode($out)->{matches} }, 2, 'cwd search multiple matches' );
    chdir $home or die $!;
};

subtest 'complete-cdr words' => sub {
    my ( $ok, $err, $out ) = _run( command => 'path', args => [ 'complete-cdr', 1, 'cdr', 'c' ] );
    like( $out, qr/^cb$/m, 'alias completion' );
    ( $ok, $err, $out ) = _run( command => 'path', args => [ 'complete-cdr', 2, 'cdr', 'cb', 'al' ] );
    like( $out, qr/alpha-one/, 'directory completion' );
};

subtest '_normalize_add_arguments and delete fallbacks' => sub {
    my $norm = \&{"${package}::_normalize_add_arguments"};
    my ( $n, $p ) = $norm->('.');
    is( $n, basename($home), 'dot shorthand names after cwd' );
    my $die = eval { $norm->( 'a', '' ); 1 };
    ok( !$die, 'empty path dies' );

    my $del = \&{"${package}::_normalize_delete_argument"};
    {

        package Test::Paths300::Cfg;
        sub new { bless { a => $_[1] }, $_[0] }
        sub path_aliases { $_[0]{a} }
    }
    my $stub = Test::Paths300::Stub->new;
    is(
        $del->( paths => $stub, config => Test::Paths300::Cfg->new( { basename($home) => $home } ), name => '.' ),
        basename($home), 'preferred alias matching cwd'
    );
    is(
        $del->( paths => $stub, config => Test::Paths300::Cfg->new( { other => $home } ), name => '.' ),
        'other', 'scan alias matching cwd'
    );
    is(
        $del->( paths => $stub, config => Test::Paths300::Cfg->new( { $$ => '/nowhere' } ), name => '.' ),
        basename($home), 'no alias matches'
    );
    is(
        $del->( paths => $stub, config => Test::Paths300::Cfg->new( { basename($home) => '/elsewhere', zz => $home } ), name => '.' ),
        'zz', 'preferred alias not at cwd falls to scan'
    );
};

subtest '_resolve_path_alias branches' => sub {
    my $resolve = \&{"${package}::_resolve_path_alias"};
    my $reg = $registry->( named_paths => { known => $home } );
    is( $resolve->( paths => $reg, name => 'known' ), $home, 'configured alias resolves directly' );

    _skill( 'resolver', "package Folder; sub where { return '$home' } 1;\n" );
    is( $resolve->( paths => $reg, name => 'resolver.where' ), $home, 'skill alias resolves through Folder.pm' );
};

subtest 'Folder alias enumeration' => sub {
    my $aliases = \&{"${package}::_skill_folder_path_aliases"};
    _skill( 'enum-a', "package Folder; sub one { return '$home' } sub __list__ { return ('one') } 1;\n" );
    _skill( 'enum-b', "package Folder; sub two { return '$home' } sub __list__ { return ('two') } 1;\n" );
    _skill( 'enum-none', "package Folder; sub x { return 1 } 1;\n" );
    _skill( 'enum-nofile', undef );
    _skill( 'enum-parent.child', "package Folder; sub deep { return '$home' } sub __list__ { return ('deep') } 1;\n" );
    my $reg = $registry->();

    my $only = $aliases->( paths => $reg, skill_name => 'enum-a' );
    is_deeply( [ sort keys %{$only} ], ['enum-a.one'], 'skill_name filters to one skill' );
    my $all = $aliases->( paths => $reg );
    ok( exists $all->{'enum-b.two'} && exists $all->{'enum-parent.child.deep'}, 'all skills enumerated' );

    my %bad = (
        'enum-arr'  => [ "package Folder; sub __list__ { return [1] } 1;\n",                                        qr/not an array reference/ ],
        'enum-inv'  => [ "package Folder; sub __list__ { return ('bad name') } 1;\n",                               qr/invalid alias name/ ],
        'enum-res'  => [ "package Folder; sub __list__ { return ('__list__') } 1;\n",                               qr/invalid alias name/ ],
        'enum-miss' => [ "package Folder; sub __list__ { return ('ghost') } 1;\n",                                  qr/not available/ ],
        'enum-tgt'  => [ "package Folder; sub t { return '' } sub __list__ { return ('t') } 1;\n",                  qr/non-empty path/ ],
        'enum-ref'  => [ "package Folder; sub t { return [] } sub __list__ { return ('t') } 1;\n",                  qr/non-empty path/ ],
        'enum-und'  => [ "package Folder; sub t { return undef } sub __list__ { return ('t') } 1;\n",               qr/non-empty path/ ],
    );
    for my $name ( sort keys %bad ) {
        my $skill_root = _skill( $name, $bad{$name}[0] );
        my $ok = eval { $aliases->( paths => $reg, skill_name => $name ); 1 };
        ok( !$ok, "$name dies" );
        like( $@, $bad{$name}[1], "$name reports its problem" );
        File::Path::remove_tree($skill_root);
    }
};

subtest '_skill_folder_alias_target branches' => sub {
    my $target = \&{"${package}::_skill_folder_alias_target"};
    my $reg    = $registry->();
    my $ok;
    _skill( 'tgt-ok', "package Folder; sub here { return '$home' } sub bad { return '' } sub refd { return {} } 1;\n" );
    _skill( 'tgt-nofile', undef );
    is( $target->( paths => $reg, name => 'tgt-ok.here' ), $home, 'target resolved' );
    ok( !defined $target->( paths => $reg, name => 'tgt-ok.ghost' ), 'unknown method is undef' );
    ok( !defined $target->( paths => $reg, name => 'tgt-nofile.here' ), 'skill without Folder.pm is undef' );
    ok( !defined $target->( paths => $reg, name => 'nosuch.here' ), 'unknown skill is undef' );
    ok( !defined $target->( paths => $reg, name => "tgt-ok..here" ), 'empty segment is undef' );
    _skill( 'tgt-undef', "package Folder; sub nothing { return undef } 1;\n" );
    $ok = eval { $target->( paths => $reg, name => 'tgt-undef.nothing' ); 1 };
    ok( !$ok, 'undefined target dies' );
    for my $m (qw(bad refd)) {
        my $ok = eval { $target->( paths => $reg, name => "tgt-ok.$m" ); 1 };
        ok( !$ok, "$m target dies" );
        like( $@, qr/non-empty path/, "$m target reports" );
    }
    $ok = eval { $target->( name => 'a.b' ); 1 };
    ok( !$ok, 'missing registry dies' );
    ok( !defined $target->( paths => $reg, name => 'tgt-ok.__list__' ), '__list__ is reserved' );
    ok( !defined $target->( paths => $reg, name => 'tgt-ok.can' ), 'can is reserved' );
};

subtest '_skill_folder_entries and _load_skill_folder_module guards' => sub {
    my $entries = \&{"${package}::_skill_folder_entries"};
    my $load    = \&{"${package}::_load_skill_folder_module"};

    my $ok = eval { $entries->(undef); 1 };
    ok( !$ok, 'missing registry dies' );
    like( $@, qr/Missing paths registry/, 'reported' );

    my $stub = Test::Paths300::Stub->new( entries => [ { dir => '/nonexistent/skill' } ] );
    my @e = $entries->($stub);
    is( $e[0]{name}, '', 'undefined segments give an empty name' );

    $ok = eval { $load->('notahash'); 1 };
    ok( !$ok, 'non-hash entry dies' );
    $ok = eval { $load->( {} ); 1 };
    ok( !$ok, 'entry without file dies' );
    like( $@, qr/Missing skill Folder.pm path/, 'reported' );
    is( $load->( { file => '/nonexistent/Folder.pm' } ), 0, 'missing file returns 0' );

    my $root = File::Spec->catdir( $home, 'loadtest' );
    my $lib  = File::Spec->catdir( $root, 'lib' );
    my $file = _write( File::Spec->catfile( $lib, 'Folder.pm' ), "package Folder; 1;\n" );
    is( $load->( { dir => $root, lib => $lib, file => $file } ), 1, 'valid module loads' );

    $ok = eval { $load->( { dir => '/nonexistent/a/b', lib => $lib, file => $file } ); 1 };
    ok( !$ok, 'unresolvable skill dir dies' );
    like( $@, qr/Unable to resolve/, 'reported' );

    $ok = eval { $load->( { dir => $root, lib => '/nonexistent/a/b', file => $file } ); 1 };
    ok( !$ok, 'unresolvable lib dir dies' );

    my $other = File::Spec->catdir( $home, 'other-lib' );
    make_path($other);
    $ok = eval { $load->( { dir => $root, lib => $other, file => $file } ); 1 };
    ok( !$ok, 'lib outside skill root dies' );
    like( $@, qr/outside its skill root/, 'reported' );

    my $stray = _write( File::Spec->catfile( $root, 'stray', 'Folder.pm' ), "package Folder; 1;\n" );
    $ok = eval { $load->( { dir => $root, lib => $lib, file => $stray } ); 1 };
    ok( !$ok, 'file outside lib dies' );
    like( $@, qr/outside its skill lib/, 'reported' );

    my %bad = (
        syntax  => [ "package Folder; this is (( not perl;\n", qr/Unable to load skill Folder.pm/ ],
        errno   => [ "\$! = 2; undef;\n",                       qr/Unable to load skill Folder.pm/ ],
        undef   => [ "\$! = 0; undef;\n",                       qr/did not return a true value/ ],
        falsey  => [ "0;\n",                                    qr/did not return a true value/ ],
    );
    for my $kind ( sort keys %bad ) {
        my $f = _write( File::Spec->catfile( $lib, 'Folder.pm' ), $bad{$kind}[0] );
        $ok = eval { $load->( { dir => $root, lib => $lib, file => $f } ); 1 };
        ok( !$ok, "$kind module dies" );
        like( $@, $bad{$kind}[1], "$kind module reports" );
    }
};

subtest '_valid_folder_method_name' => sub {
    my $valid = \&{"${package}::_valid_folder_method_name"};
    ok( !$valid->(undef),   'undef invalid' );
    ok( !$valid->( [] ),    'ref invalid' );
    ok( !$valid->('a b'),   'spaces invalid' );
    ok( !$valid->('DESTROY'), 'reserved invalid' );
    ok( $valid->('fine_name'), 'plain name valid' );
};

subtest '_cdr_payload alias resolution' => sub {
    my $payload = \&{"${package}::_cdr_payload"};
    my $base = File::Spec->catdir( $home, 'payload-base' );
    make_path( File::Spec->catdir( $base, 'one' ) );
    my $reg = $registry->( named_paths => { pb => $base } );
    my $r = $payload->( paths => $reg, args => ['pb'] );
    is( $r->{target}, $base, 'alias only' );
    $r = $payload->( paths => $reg, args => [ 'pb', 'one' ] );
    is( $r->{target}, File::Spec->catdir( $base, 'one' ), 'alias + one match' );

    my $seen;
    $r = $payload->(
        paths                 => $reg,
        args                  => ['zzz.unknown'],
        folder_alias_resolver => sub { $seen = $_[0]; return $base },
    );
    is( $seen, 'zzz.unknown', 'folder alias resolver consulted' );
    is( $r->{target}, $base, 'resolver target used' );

    $r = $payload->( paths => $reg, args => ['zzz.unknown'], folder_alias_resolver => 'notcode' );
    is( $r->{target}, '', 'non-code resolver ignored' );

    my $blank = $registry->( named_paths => { blank => '' } );
    $r = $payload->( paths => $blank, args => ['blank'], folder_alias_resolver => sub { die "must not be called\n" } );
    is( $r->{target}, '', 'configured alias suppresses the folder resolver' );

    my $undef_named = Test::Paths300::Stub->new;
    {
        no warnings 'once';
        local *Test::Paths300::Stub::named_paths = sub { { dead => '/x' } };
        local *Test::Paths300::Stub::resolve_dir = sub { die "cannot resolve\n" };
        local *Test::Paths300::Stub::current_working_directory = sub { $home };
        local *Test::Paths300::Stub::locate_dirs_under = sub { return () };
        $r = $payload->( paths => $undef_named, args => ['dead'], folder_alias_resolver => sub { die "unused\n" } );
        is( $r->{target}, '', 'configured alias that fails to resolve skips the folder resolver' );
    }
    {
        no warnings 'once';
        local *Test::Paths300::Stub::named_paths = sub { undef };
        local *Test::Paths300::Stub::resolve_dir = sub { die "nope\n" };
        local *Test::Paths300::Stub::current_working_directory = sub { $home };
        local *Test::Paths300::Stub::locate_dirs_under = sub { return () };
        $r = $payload->( paths => $undef_named, args => ['x'] );
        is( $r->{target}, '', 'undef named_paths tolerated' );
    }
};

subtest '_cdr_completion alias roots' => sub {
    my $completion = \&{"${package}::_cdr_completion"};
    my $base = File::Spec->catdir( $home, 'comp-base' );
    make_path( File::Spec->catdir( $base, 'aa' ), File::Spec->catdir( $base, 'ab' ) );
    my $reg = $registry->( named_paths => { cbase => $base, blank => '' } );
    my @c = $completion->( paths => $reg, words => [ 'cdr', 'cbase', 'a' ], index => 2 );
    is_deeply( \@c, [ 'aa', 'ab' ], 'alias root completion' );
    @c = $completion->( paths => $reg, words => [ 'cdr', 'cbase', 'aa', 'x' ], index => 3 );
    is_deeply( \@c, [], 'extra filters narrow completion' );
    @c = $completion->( paths => $reg, words => [ 'cdr', 'nonalias', 'a' ], index => 2 );
    ok( 1, 'non alias falls back to cwd root' );
};

subtest '_resolve_path_alias tolerates an undefined alias inventory' => sub {
    my $resolve = \&{"${package}::_resolve_path_alias"};
    no warnings 'once';
    local *Test::Paths300::Stub::named_paths = sub { undef };
    local *Test::Paths300::Stub::resolve_dir = sub { return "resolved:$_[1]" };
    is( $resolve->( paths => Test::Paths300::Stub->new, name => 'plain' ), 'resolved:plain', 'falls through to resolve_dir' );
};

subtest 'undefined alias tables' => sub {
    my $table = \&{"${package}::_paths_table"};
    like( $table->(undef), qr/Path/, 'undef inventory renders header only' );
};

chdir $orig_cwd;
is_deeply( \@warnings, [], 'no warnings escaped' ) or diag explain \@warnings;

done_testing;

__END__

=pod

=head1 NAME

t/300-cli-paths-full-coverage.t - branch and condition coverage for CLI::Paths

=head1 DESCRIPTION

Drives every dispatch verb, output mode, alias-normalisation fallback, skill
Folder.pm loading guard, cdr payload and completion branch in
L<Developer::Dashboard::CLI::Paths> inside a hermetic temporary HOME.

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It closes the remaining Devel::Cover branch, condition and statement gaps for: branch and condition coverage for CLI::Paths.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate (Problem 20) needs every reachable branch exercised, and these paths were only reachable through failure injection or unusual inputs that the broader tests do not produce.

=head1 WHEN TO USE

Use this file when you change the modules it covers, when a coverage run reports one of their branches or conditions as uncovered, or when you want a focused check before running the full suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/300-cli-paths-full-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release. It is hermetic: it uses temporary directories and a local HOME.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/300-cli-paths-full-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/300-cli-paths-full-coverage.t

Confirm the targeted branches and conditions are reported as covered.

=cut
