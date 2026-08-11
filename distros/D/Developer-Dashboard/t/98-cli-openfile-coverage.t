#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use File::Spec::Functions qw(catdir catfile);
use Cwd qw(getcwd);
use Capture::Tiny qw(capture);
use HTTP::Response;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);

use lib 'lib';

use Developer::Dashboard::CLI::OpenFile qw(build_path_registry run_open_file_command);
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;

my $PKG = 'Developer::Dashboard::CLI::OpenFile';

# oc($function_name, @args)
# Calls one private OpenFile helper by name, preserving list/scalar context.
# Input: helper function name string plus its argument list.
# Output: whatever the underlying helper returns.
sub oc {
    my $fn = shift;
    no strict 'refs';
    return &{"${PKG}::${fn}"}(@_);
}

# spew($path, $content)
# Writes a small fixture file for the open-file lookups under test.
# Input: destination path string and content string.
# Output: nothing.
sub spew {
    my ( $path, $content ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    return;
}

# write_jar($path, \%entries)
# Builds a deterministic zip archive used as a Java source jar fixture.
# Input: archive path string and hash reference of member name to content.
# Output: nothing.
sub write_jar {
    my ( $path, $entries ) = @_;
    my $zip = Archive::Zip->new;
    for my $name ( sort keys %{$entries} ) {
        $zip->addString( $entries->{$name}, $name );
    }
    my $status = $zip->writeToFileNamed($path);
    die "Unable to write jar $path\n" if $status != AZ_OK;
    return;
}

# --- Hermetic runtime rooted in a private temp home -------------------------
my $orig_cwd = getcwd();
my $home     = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

# build_path_registry() reads $ENV{HOME}; give it two of the three roots so the
# -d filter runs but its defined guard (annotated uncoverable) is exercised.
make_path( catdir( $home, 'projects' ) );
make_path( catdir( $home, 'src' ) );

my $reg = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home );

# ---------------------------------------------------------------------------
# build_path_registry
# ---------------------------------------------------------------------------
{
    my $registry = build_path_registry();
    isa_ok( $registry, 'Developer::Dashboard::PathRegistry', 'build_path_registry returns a registry' );
}

# ---------------------------------------------------------------------------
# _default_editor : every operand of the fallback chain
# ---------------------------------------------------------------------------
{
    local $ENV{VISUAL} = 'vis';
    local $ENV{EDITOR} = 'ed';
    is( oc( '_default_editor', 'myed' ), 'myed', 'explicit editor wins' );
    is( oc( '_default_editor', '' ),     'vis',  'empty editor falls to VISUAL' );
}
{
    local $ENV{VISUAL};
    delete $ENV{VISUAL};
    local $ENV{EDITOR} = 'ed';
    is( oc( '_default_editor', '' ), 'ed', 'no VISUAL falls to EDITOR' );
}
{
    local $ENV{VISUAL};
    delete $ENV{VISUAL};
    local $ENV{EDITOR};
    delete $ENV{EDITOR};
    is( oc( '_default_editor', '' ), 'vim', 'empty editor and env falls to vim' );
}

# ---------------------------------------------------------------------------
# _editor_supports_tabs
# ---------------------------------------------------------------------------
ok( oc( '_editor_supports_tabs', command => ['vim'] ),            'vim supports tabs' );
ok( oc( '_editor_supports_tabs', command => ['/usr/bin/nvim'] ), 'path-qualified nvim supports tabs' );
ok( !oc( '_editor_supports_tabs', command => ['code'] ),         'non-vim editor does not' );
ok( !oc('_editor_supports_tabs'),                                'missing command yields no tabs' );
ok( !oc( '_editor_supports_tabs', command => [''] ),             'empty editor name yields no tabs' );

# ---------------------------------------------------------------------------
# _unique_matches : undef, empty, and duplicate inputs
# ---------------------------------------------------------------------------
is_deeply( [ oc( '_unique_matches', undef, '', 'x', 'x', 'y' ) ], [ 'x', 'y' ], 'unique matches filters undef/empty/dups' );

# ---------------------------------------------------------------------------
# _selection_matches
# ---------------------------------------------------------------------------
is_deeply( [ oc( '_selection_matches', matches => [ 'a', 'b' ] ) ], [ 'a', 'b' ], 'undef choices returns all matches' );
is_deeply( [ oc( '_selection_matches', choices => '' ) ],           [],           'empty choices with empty matches yields none' );
is_deeply( [ oc( '_selection_matches', choices => '1' ) ],          [],           'chunk beyond empty matches returns none' );
is_deeply( [ oc( '_selection_matches', choices => '0-2', matches => [ 'a', 'b', 'c' ] ) ], [], 'range start below one rejected' );
is_deeply( [ oc( '_selection_matches', choices => '3-2', matches => [ 'a', 'b', 'c' ] ) ], [], 'reversed range rejected' );
is_deeply( [ oc( '_selection_matches', choices => '1-9', matches => [ 'a', 'b' ] ) ],      [], 'range end beyond size rejected' );
is_deeply( [ oc( '_selection_matches', choices => '1-2', matches => [ 'a', 'b', 'c' ] ) ], [ 'a', 'b' ], 'valid range selects span' );
is_deeply( [ oc( '_selection_matches', choices => '0', matches => [ 'a', 'b' ] ) ],        [], 'chunk below one rejected' );
is_deeply( [ oc( '_selection_matches', choices => '2', matches => [ 'a', 'b', 'c' ] ) ],   [ 'b' ], 'single index selects one' );
is_deeply( [ oc( '_selection_matches', choices => '1,3', matches => [ 'a', 'b', 'c' ] ) ], [ 'a', 'c' ], 'comma list selects several' );

# ---------------------------------------------------------------------------
# _select_open_file_matches : chooser flow with mocked stdin
# ---------------------------------------------------------------------------
is_deeply( [ oc('_select_open_file_matches') ],                     [],         'no matches selects nothing' );
is_deeply( [ oc( '_select_open_file_matches', matches => ['solo'] ) ], ['solo'], 'single match returns immediately' );
{
    my @m;
    capture {
        my $empty = '';
        open my $in, '<', \$empty or die $!;
        local *STDIN = $in;
        @m = oc( '_select_open_file_matches', matches => [ 'a', 'b' ] );
    };
    is_deeply( \@m, [ 'a', 'b' ], 'EOF at prompt returns all matches' );
}
{
    my @m;
    capture {
        my $s = "2\n";
        open my $in, '<', \$s or die $!;
        local *STDIN = $in;
        @m = oc( '_select_open_file_matches', matches => [ 'a', 'b' ] );
    };
    is_deeply( \@m, ['b'], 'numeric selection picks the chosen match' );
}
{
    my @m;
    capture {
        my $s = "\n";
        open my $in, '<', \$s or die $!;
        local *STDIN = $in;
        @m = oc( '_select_open_file_matches', matches => [ 'a', 'b' ] );
    };
    is_deeply( \@m, [ 'a', 'b' ], 'blank line selects all matches' );
}
{
    my $err;
    capture {
        my $s = "nope\n";
        open my $in, '<', \$s or die $!;
        local *STDIN = $in;
        eval { oc( '_select_open_file_matches', matches => [ 'a', 'b' ] ) };
        $err = $@;
    };
    like( $err, qr/Invalid file selection 'nope'/, 'invalid selection dies' );
}

# ---------------------------------------------------------------------------
# _ordered_scope_matches
# ---------------------------------------------------------------------------
is_deeply(
    [ oc( '_ordered_scope_matches', files => [ 'b.txt', 'a.txt', 'b.txt' ] ) ],
    [ 'b.txt', 'a.txt' ],
    'equal-rank ordering falls back to discovery order',
);
is_deeply(
    [
        oc(
            '_ordered_scope_matches',
            patterns => ['a'],
            entries  => [ { file => 'z.txt', match_path => 'z.txt' }, { file => 'a.txt', match_path => 'a.txt' } ],
        )
    ],
    [ 'a.txt', 'z.txt' ],
    'pattern rank ordering promotes the stronger match',
);

# ---------------------------------------------------------------------------
# _scope_match_rank
# ---------------------------------------------------------------------------
is( oc( '_scope_match_rank', file => 'x.txt' ), 0, 'no patterns yields a zero rank' );
{
    my $r1 = oc( '_scope_match_rank', patterns => ['x'] );
    my $r2 = oc( '_scope_match_rank', match_path => 'dir/', patterns => ['x'] );
    my $r3 = oc( '_scope_match_rank', match_path => 'App.pm', patterns => ['App'] );
    my $r4 = oc( '_scope_match_rank', match_path => '/a/b', patterns => [ undef, '', 'a' ] );
    ok( defined $r1 && defined $r2 && defined $r3 && defined $r4, 'rank scoring handles empty, trailing-slash and undef inputs' );
}

# ---------------------------------------------------------------------------
# _open_file_registries
# ---------------------------------------------------------------------------
eval { oc('_open_file_registries') };
like( $@, qr/Missing path registry/, '_open_file_registries requires paths' );
{
    my ( $files, $config ) = oc( '_open_file_registries', paths => $reg );
    isa_ok( $files,  'Developer::Dashboard::FileRegistry', 'registries file object' );
    isa_ok( $config, 'Developer::Dashboard::Config',       'registries config object' );
}

# ---------------------------------------------------------------------------
# _scope_relative_path_match
# ---------------------------------------------------------------------------
my $subdir = catdir( $home, 'subdir' );
make_path($subdir);
spew( catfile( $subdir, 'rel.txt' ), "rel\n" );

is_deeply( [ oc('_scope_relative_path_match') ],                                     [], 'missing scope returns nothing' );
is_deeply( [ oc( '_scope_relative_path_match', scope => $subdir ) ],                 [], 'missing pattern returns nothing' );
is_deeply( [ oc( '_scope_relative_path_match', scope => $subdir, pattern => [undef] ) ], [], 'undef pattern member returns nothing' );
is_deeply( [ oc( '_scope_relative_path_match', scope => $subdir, pattern => [''] ) ],    [], 'empty pattern member returns nothing' );
is( oc( '_scope_relative_path_match', scope => $subdir, pattern => ['rel.txt'] ), catfile( $subdir, 'rel.txt' ), 'existing relative path resolves' );
is( oc( '_scope_relative_path_match', scope => $subdir, pattern => ['nope.txt'] ), undef, 'missing relative path yields undef' );

# ---------------------------------------------------------------------------
# _named_source_matches guards + Perl module + Java class resolution
# ---------------------------------------------------------------------------
eval { oc('_named_source_matches') };
like( $@, qr/Missing path registry/, '_named_source_matches requires paths' );
is_deeply( [ oc( '_named_source_matches', paths => $reg ) ], [], 'missing name yields no matches' );

# Perl module resolution via @INC (no archive/network path is taken for :: names).
{
    make_path( catdir( $home, 'plib', 'My' ) );
    spew( catfile( $home, 'plib', 'My', 'Mod.pm' ), "package My::Mod;\n1;\n" );
    local @INC = ( $home, catdir( $home, 'plib' ), @INC );
    my @pm = oc( '_named_source_matches', paths => $reg, name => 'My::Mod' );
    ok( ( grep { m{Mod\.pm$} } @pm ), 'Perl module name resolves to a source file' );
}

# ---------------------------------------------------------------------------
# _open_file_roots : deduped, filtered root list
# ---------------------------------------------------------------------------
eval { oc('_open_file_roots') };
like( $@, qr/Missing path registry/, '_open_file_roots requires paths' );
{
    my $scandir = catdir( $home, 'scan_empty' );
    make_path($scandir);
    my $wsdir = catdir( $home, 'wsdir' );
    make_path($wsdir);
    my $noexist = catdir( $home, 'noexist-xyz' );
    my $mreg    = Developer::Dashboard::PathRegistry->new(
        home            => $home,
        cwd             => $scandir,
        workspace_roots => [ '', $noexist, $wsdir ],
        project_roots   => [$wsdir],
    );
    my @roots = oc( '_open_file_roots', paths => $mreg );
    ok( ( grep { $_ eq $wsdir } @roots ), 'existing workspace root survives filtering' );
    ok( !( grep { !defined $_ } @roots ), 'undef roots are dropped from the result' );
}

# ---------------------------------------------------------------------------
# _existing_named_files
# ---------------------------------------------------------------------------
is_deeply( [ oc( '_existing_named_files', roots => [$home] ) ], [], 'missing relative returns nothing' );
is_deeply( [ oc( '_existing_named_files', relative => 'x' ) ],  [], 'no roots returns nothing' );
{
    make_path( catdir( $home, 'pkg' ) );
    spew( catfile( $home, 'pkg', 'Demo.pm' ), "package pkg::Demo;\n1;\n" );
    my @f = oc( '_existing_named_files', roots => [$home], relative => catfile( 'pkg', 'Demo.pm' ), prefixes => [ '', '' ] );
    is_deeply( \@f, [ catfile( $home, 'pkg', 'Demo.pm' ) ], 'duplicate prefixes resolve to one file' );
    is_deeply( [ oc( '_existing_named_files', roots => [$home], relative => catfile( 'no', 'such.pm' ) ) ], [], 'absent relative yields none' );
}

# ---------------------------------------------------------------------------
# _compile_open_file_regex
# ---------------------------------------------------------------------------
is( oc( '_compile_open_file_regex', undef ), undef, 'undef pattern compiles to undef' );
is( oc( '_compile_open_file_regex', '' ),    undef, 'empty pattern compiles to undef' );
isa_ok( oc( '_compile_open_file_regex', 'abc' ), 'Regexp', 'valid pattern compiles' );
eval { oc( '_compile_open_file_regex', '(' ) };
like( $@, qr/Invalid regex/, 'invalid pattern dies' );

# ---------------------------------------------------------------------------
# _java_source_archive_roots + _candidate_java_source_archives
# ---------------------------------------------------------------------------
eval { oc('_java_source_archive_roots') };
like( $@, qr/Missing path registry/, '_java_source_archive_roots requires paths' );
{
    my $wsdir = catdir( $home, 'wsdir' );
    local $ENV{JAVA_HOME} = $home;      # defined + existing directory
    local $ENV{JDK_HOME};
    delete $ENV{JDK_HOME};              # undefined -> defined guard false side
    my @r = oc(
        '_java_source_archive_roots',
        paths => $reg,
        roots => [ undef, '', catdir( $home, 'nope-xyz' ), $wsdir, $wsdir ],
    );
    ok( ( grep { $_ eq $wsdir } @r ), 'existing archive root retained' );
    ok( ( grep { $_ eq $home } @r ),  'JAVA_HOME contributes an archive root' );
}
{
    # Omitted roots exercise the default empty-list fallback.
    local $ENV{JAVA_HOME};
    delete $ENV{JAVA_HOME};
    local $ENV{JDK_HOME};
    delete $ENV{JDK_HOME};
    my @r = oc( '_java_source_archive_roots', paths => $reg );
    ok( !( grep { !defined $_ } @r ), 'default archive roots contain no undef entries' );
}

eval { oc('_candidate_java_source_archives') };
like( $@, qr/Missing path registry/, '_candidate_java_source_archives requires paths' );
{
    local $ENV{JAVA_HOME};
    delete $ENV{JAVA_HOME};
    local $ENV{JDK_HOME};
    delete $ENV{JDK_HOME};
    is_deeply( [ oc( '_candidate_java_source_archives', paths => $reg, roots => [] ) ], [], 'no candidate archives when roots are empty' );
    is_deeply( [ oc( '_candidate_java_source_archives', paths => $reg ) ], [], 'no candidate archives when roots are omitted' );

    my $arcparent = catdir( $home, 'arcparent' );
    my $arctest   = catdir( $arcparent, 'arctest' );
    make_path($arctest);
    my $arcjar = catfile( $arctest, 'lib-sources.jar' );
    write_jar( $arcjar, { 'a/B.java' => "class B {}\n" } );
    my @arch = oc( '_candidate_java_source_archives', paths => $reg, roots => [ $arctest, $arcparent ] );
    is_deeply( \@arch, [$arcjar], 'overlapping roots dedupe the repeated archive path' );
}

# ---------------------------------------------------------------------------
# _matching_java_archive_entries + _extract_java_sources_from_archive
# ---------------------------------------------------------------------------
is_deeply( [ oc('_matching_java_archive_entries') ], [], 'missing zip yields no entries' );
{
    my $z = Archive::Zip->new;
    is_deeply( [ oc( '_matching_java_archive_entries', zip => $z ) ], [], 'missing relative yields no entries' );
}
{
    # A member with an empty file name is skipped while the real member matches.
    my $z = Archive::Zip->new;
    $z->addString( 'blank', '' );
    $z->addString( "class Foo {}\n", 'com/example/Foo.java' );
    my @entries = oc( '_matching_java_archive_entries', zip => $z, relative => catfile( 'com', 'example', 'Foo.java' ) );
    is_deeply( \@entries, ['com/example/Foo.java'], 'blank-named members are skipped during matching' );
}

eval { oc('_extract_java_sources_from_archive') };
like( $@, qr/Missing path registry/, '_extract_java_sources_from_archive requires paths' );
is_deeply( [ oc( '_extract_java_sources_from_archive', paths => $reg ) ], [], 'missing archive yields no sources' );
is_deeply( [ oc( '_extract_java_sources_from_archive', paths => $reg, archive => '/x' ) ], [], 'missing relative yields no sources' );

my $good_relative = catfile( 'com', 'example', 'Foo.java' );
{
    my $jar = catfile( $home, 'src-jar.jar' );
    write_jar( $jar, { 'com/example/Foo.java' => "class Foo {}\n", 'other/Bar.txt' => "note\n" } );
    my @x = oc( '_extract_java_sources_from_archive', paths => $reg, archive => $jar, relative => $good_relative );
    ok( ( @x && -f $x[0] ), 'matching archive member is extracted to disk' );
}
{
    my $bad = catfile( $home, 'bad.jar' );
    spew( $bad, "this is not a zip archive\n" );
    my $old = Archive::Zip::setErrorHandler( sub { } );
    my @y = oc( '_extract_java_sources_from_archive', paths => $reg, archive => $bad, relative => $good_relative );
    Archive::Zip::setErrorHandler($old) if $old;
    is_deeply( \@y, [], 'unreadable archive yields no sources' );
}
{
    # An entry name that does not resolve to a member is skipped during extraction.
    my $jar = catfile( $home, 'src-jar.jar' );
    no warnings 'redefine';
    local *Developer::Dashboard::CLI::OpenFile::_matching_java_archive_entries = sub { return ('missing/Absent.java') };
    my @z = oc( '_extract_java_sources_from_archive', paths => $reg, archive => $jar, relative => $good_relative );
    is_deeply( \@z, [], 'unresolvable archive entry names are skipped' );
}

# ---------------------------------------------------------------------------
# _cached_archive_source_path
# ---------------------------------------------------------------------------
eval { oc('_cached_archive_source_path') };
like( $@, qr/Missing path registry/, '_cached_archive_source_path requires paths' );
eval { oc( '_cached_archive_source_path', paths => $reg ) };
like( $@, qr/Missing archive path/, '_cached_archive_source_path requires archive' );
eval { oc( '_cached_archive_source_path', paths => $reg, archive => 'a.jar' ) };
like( $@, qr/Missing archive entry/, '_cached_archive_source_path requires entry' );
like(
    oc( '_cached_archive_source_path', paths => $reg, archive => 'a.jar', entry => 'com/example/Foo.java' ),
    qr{open-file[/\\]java-sources},
    'cached archive path lives under the open-file cache tree',
);

# ---------------------------------------------------------------------------
# _java_archive_source_matches guards
# ---------------------------------------------------------------------------
eval { oc('_java_archive_source_matches') };
like( $@, qr/Missing path registry/, '_java_archive_source_matches requires paths' );
is_deeply( [ oc( '_java_archive_source_matches', paths => $reg ) ], [], 'missing name yields no archive matches' );
is_deeply( [ oc( '_java_archive_source_matches', paths => $reg, name => 'com.X.Y' ) ], [], 'missing relative yields no archive matches' );
{
    # A local source jar satisfies the lookup without any network download.
    local $ENV{JAVA_HOME};
    delete $ENV{JAVA_HOME};
    local $ENV{JDK_HOME};
    delete $ENV{JDK_HOME};
    my $archdir = catdir( $home, 'archdir' );
    make_path($archdir);
    write_jar( catfile( $archdir, 'demo-sources.jar' ), { 'com/example/Foo.java' => "class Foo {}\n" } );
    my @m = oc(
        '_java_archive_source_matches',
        paths    => $reg,
        roots    => [$archdir],
        name     => 'com.example.Foo',
        relative => $good_relative,
    );
    ok( @m, 'local source jar resolves the Java class without downloading' );
}

# ---------------------------------------------------------------------------
# _maven_search_documents : query, transport and payload handling
# ---------------------------------------------------------------------------
is_deeply( [ oc( '_maven_search_documents', undef ) ], [], 'undef class name yields no documents' );
is_deeply( [ oc( '_maven_search_documents', '' ) ],    [], 'empty class name yields no documents' );
{
    no warnings 'redefine';
    local *LWP::UserAgent::get = sub { HTTP::Response->new( 200, 'OK', [], '{"response":{"docs":[{"a":"art"}]}}' ) };
    my @d = oc( '_maven_search_documents', 'com.example.Foo' );
    is( scalar(@d), 1, 'search returns the parsed document rows' );
    is( $d[0]{a}, 'art', 'search preserves artifact coordinates' );

    local *LWP::UserAgent::get = sub { HTTP::Response->new( 200, 'OK', [], '{}' ) };
    is_deeply( [ oc( '_maven_search_documents', 'com.X' ) ], [], 'missing docs list yields no documents' );

    local *LWP::UserAgent::get = sub { HTTP::Response->new( 500, 'Err', [], '' ) };
    is_deeply( [ oc( '_maven_search_documents', 'com.X' ) ], [], 'transport failure yields no documents' );

    local *LWP::UserAgent::get = sub { HTTP::Response->new( 200, 'OK', [], 'not json' ) };
    is_deeply( [ oc( '_maven_search_documents', 'com.X' ) ], [], 'unparsable payload yields no documents' );

    local *LWP::UserAgent::get = sub { HTTP::Response->new( 200, 'OK', [], '[]' ) };
    is_deeply( [ oc( '_maven_search_documents', 'com.X' ) ], [], 'non-object payload yields no documents' );
}

# ---------------------------------------------------------------------------
# _download_maven_source_jar : coordinates, mirror status, and cache reuse
# ---------------------------------------------------------------------------
eval { oc('_download_maven_source_jar') };
like( $@, qr/Missing path registry/, '_download_maven_source_jar requires paths' );
is( oc( '_download_maven_source_jar', paths => $reg ),                    undef, 'missing document yields no jar' );
is( oc( '_download_maven_source_jar', paths => $reg, doc => 'str' ),      undef, 'non-object document yields no jar' );
is( oc( '_download_maven_source_jar', paths => $reg, doc => { a => 'a', v => '1' } ), undef, 'missing group yields no jar' );
is( oc( '_download_maven_source_jar', paths => $reg, doc => { g => 'g', v => '1' } ), undef, 'missing artifact yields no jar' );
is( oc( '_download_maven_source_jar', paths => $reg, doc => { g => 'g', a => 'a' } ), undef, 'missing version yields no jar' );
{
    no warnings 'redefine';
    local *LWP::UserAgent::mirror = sub {
        my ( $self, $url, $target ) = @_;
        open my $fh, '>', $target or die "Unable to write $target: $!";
        print {$fh} 'JARBYTES';
        close $fh;
        return HTTP::Response->new( 200, 'OK', [], '' );
    };
    my $jar = oc( '_download_maven_source_jar', paths => $reg, doc => { g => 'com.ok', a => 'art', v => '1.0' } );
    ok( ( defined $jar && -f $jar ), 'successful mirror writes the source jar' );
    my $again = oc( '_download_maven_source_jar', paths => $reg, doc => { g => 'com.ok', a => 'art', v => '1.0' } );
    is( $again, $jar, 'already-cached jar is returned without mirroring' );

    local *LWP::UserAgent::mirror = sub { HTTP::Response->new( 404, 'Not Found', [], '' ) };
    is( oc( '_download_maven_source_jar', paths => $reg, doc => { g => 'com.f', a => 'f', v => '1' } ), undef, 'failed mirror yields no jar' );

    local *LWP::UserAgent::mirror = sub { HTTP::Response->new( 304, 'Not Modified', [], '' ) };
    is( oc( '_download_maven_source_jar', paths => $reg, doc => { g => 'com.nm', a => 'nm', v => '1' } ), undef, 'not-modified without a cached file yields undef' );

    local *LWP::UserAgent::mirror = sub { HTTP::Response->new( 200, 'OK', [], '' ) };
    is( oc( '_download_maven_source_jar', paths => $reg, doc => { g => 'com.nf', a => 'nf', v => '1' } ), undef, 'success without a written file yields undef' );
}

# ---------------------------------------------------------------------------
# _download_java_source_matches : document filtering across mirror results
# ---------------------------------------------------------------------------
eval { oc('_download_java_source_matches') };
like( $@, qr/Missing path registry/, '_download_java_source_matches requires paths' );
is_deeply( [ oc( '_download_java_source_matches', paths => $reg ) ], [], 'missing name yields no downloads' );
is_deeply( [ oc( '_download_java_source_matches', paths => $reg, name => 'com.X' ) ], [], 'missing relative yields no downloads' );
{
    no warnings 'redefine';
    my $good  = catfile( $home, 'dl-good-sources.jar' );
    my $empty = catfile( $home, 'dl-empty-sources.jar' );
    write_jar( $good,  { 'com/example/Foo.java' => "class Foo {}\n" } );
    write_jar( $empty, { 'other/Bar.txt'        => "note\n" } );

    local *Developer::Dashboard::CLI::OpenFile::_maven_search_documents = sub {
        return (
            'not-a-hash',
            {},
            { ec => ['other.jar'] },
            { ec => [ undef, '-sources.jar' ], g => 'g', a => 'faildl', v => '1' },
            { ec => ['-sources.jar'], g => 'g', a => 'nosrc', v => '1' },
            { ec => ['-sources.jar'], g => 'g', a => 'good',  v => '1' },
        );
    };
    local *Developer::Dashboard::CLI::OpenFile::_download_maven_source_jar = sub {
        my %args = @_;
        my $doc  = $args{doc};
        return undef  if $doc->{a} eq 'faildl';
        return $empty if $doc->{a} eq 'nosrc';
        return $good;
    };

    my @m = oc( '_download_java_source_matches', paths => $reg, name => 'com.example.Foo', relative => $good_relative );
    ok( @m, 'download flow extracts a matching source after filtering earlier documents' );
}

# ---------------------------------------------------------------------------
# _resolve_open_file_matches : direct, alias, module and scoped resolution
# ---------------------------------------------------------------------------
my $realfile = catfile( $home, 'realfile.txt' );
spew( $realfile, "alpha\n" );

eval { oc( '_resolve_open_file_matches', args => ['x'] ) };
like( $@, qr/Missing path registry/, 'resolve requires a path registry' );

{
    my ( $line, @m ) = oc( '_resolve_open_file_matches', paths => $reg, args => ["$realfile:18"] );
    is( $line, 18, 'file:line reference preserves the line' );
    is_deeply( \@m, [$realfile], 'file:line reference resolves the file' );
}
{
    my ( $line, @m ) = oc( '_resolve_open_file_matches', paths => $reg, args => [$realfile] );
    is( $line, 0, 'direct file has no line override' );
    is_deeply( \@m, [$realfile], 'direct file resolves' );
}

# File alias resolution.
{
    my $files  = Developer::Dashboard::FileRegistry->new( paths => $reg );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $reg );
    $config->save_global_file_alias( 'myfile', $realfile );
    $config->save_global_path_alias( 'myscope', $subdir );

    my ( $line, @m ) = oc( '_resolve_open_file_matches', paths => $reg, args => ['myfile'] );
    is_deeply( \@m, [$realfile], 'file alias resolves to the configured target' );

    my ( $sline, @sm ) = oc( '_resolve_open_file_matches', paths => $reg, args => [ 'myscope', 'rel.txt' ] );
    is_deeply( \@sm, [ catfile( $subdir, 'rel.txt' ) ], 'path alias scoped relative file resolves' );
}

# Perl module resolution via the full resolve path.
{
    local @INC = ( $home, catdir( $home, 'plib' ), @INC );
    my ( $line, @m ) = oc( '_resolve_open_file_matches', paths => $reg, args => ['My::Mod'] );
    ok( ( grep { m{Mod\.pm$} } @m ), 'module name resolves through the named-source path' );
}

# Fallthrough resolution paths run under an empty scope to bound the search.
{
    my $scandir = catdir( $home, 'scan_empty' );
    make_path($scandir);
    make_path( catdir( $scandir, 'reldir' ) );
    my $base = getcwd();
    chdir $scandir or die $!;
    my $sreg = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $scandir );

    my ( $nl, @nm ) = oc( '_resolve_open_file_matches', paths => $sreg );
    is( $nl, 0, 'no-argument resolve returns a zero line' );
    is_deeply( \@nm, [], 'no-argument resolve over an empty scope finds nothing' );

    my ( $ml, @mm ) = oc( '_resolve_open_file_matches', paths => $sreg, args => ["$scandir/missing:5"] );
    is_deeply( \@mm, [], 'file:line with a missing file falls through to search' );

    my ( $pl, @pm ) = oc( '_resolve_open_file_matches', paths => $sreg, args => ['alpha'] );
    is_deeply( \@pm, [], 'non-file pattern falls through to search' );

    my ( $al, @am ) = oc( '_resolve_open_file_matches', paths => $sreg, args => ['/no/such/dir/xyzzy'] );
    is_deeply( \@am, [], 'absolute non-directory scope falls through to search' );

    my ( $rl, @rm ) = oc( '_resolve_open_file_matches', paths => $sreg, args => ['reldir'] );
    is_deeply( \@rm, [], 'relative directory scope with no pattern finds nothing' );

    chdir $base or die $!;
}

# current_project_root fallback with a real git marker.
{
    my $gitdir = catdir( $home, 'gitproj' );
    make_path( catdir( $gitdir, '.git' ) );
    my $base = getcwd();
    chdir $gitdir or die $!;
    my $greg = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $gitdir );
    my ( $line, @m ) = oc( '_resolve_open_file_matches', paths => $greg, args => ['zzznomatchzz'] );
    is( $line, 0, 'project-root fallback resolve returns a zero line' );
    is_deeply( \@m, [], 'project-root fallback finds no matching files' );
    chdir $base or die $!;
}

# ---------------------------------------------------------------------------
# run_open_file_command : option parsing, print, editor and error flows
# ---------------------------------------------------------------------------
eval { run_open_file_command( paths => $reg ) };
like( $@, qr/^Usage: open-file/, 'run rejects missing arguments' );

# No paths supplied exercises build_path_registry, print mode exits cleanly.
{
    my $err;
    my ($out) = capture {
        local *Developer::Dashboard::CLI::OpenFile::_command_exit = sub { die "EXIT:$_[0]\n" };
        eval { run_open_file_command( args => [ '--print', $realfile ] ) };
        $err = $@;
    };
    like( $err, qr/^EXIT:0/, 'print mode exits through the test hook' );
    like( $out, qr/\Q$realfile\E/, 'print mode emits the resolved path' );
}

# Explicit --line preset short-circuits the line override.
{
    my $err;
    my ($out) = capture {
        local *Developer::Dashboard::CLI::OpenFile::_command_exit = sub { die "EXIT\n" };
        eval { run_open_file_command( paths => $reg, args => [ '--line', '7', '--print', $realfile ] ) };
        $err = $@;
    };
    like( $out, qr/\Q$realfile\E/, 'explicit line preset still prints the file' );
}

# file:line override feeds the line number.
{
    my $err;
    my ($out) = capture {
        local *Developer::Dashboard::CLI::OpenFile::_command_exit = sub { die "EXIT\n" };
        eval { run_open_file_command( paths => $reg, args => [ '--print', "$realfile:12" ] ) };
        $err = $@;
    };
    like( $out, qr/\Q$realfile\E/, 'file:line print still prints the file' );
}

# Editor mode with a vim-family editor adds tab and line switches.
{
    my $exec = '';
    eval {
        local *Developer::Dashboard::CLI::OpenFile::_command_exec = sub { $exec = join "\n", @_; die "EXEC\n" };
        run_open_file_command( paths => $reg, args => [ '--editor', 'vim', "$realfile:9" ] );
    };
    like( $@,    qr/^EXEC/, 'editor mode reaches the exec hook' );
    like( $exec, qr/^vim\n-p\n\+9\n\Q$realfile\E$/m, 'vim editor gets tab and line switches' );
}

# Editor mode with a non-vim editor and no line stays minimal.
{
    my $exec = '';
    eval {
        local *Developer::Dashboard::CLI::OpenFile::_command_exec = sub { $exec = join "\n", @_; die "EXEC\n" };
        run_open_file_command( paths => $reg, args => [ '--editor', 'fakeed', $realfile ] );
    };
    like( $exec, qr/^fakeed\n\Q$realfile\E$/m, 'non-vim editor gets neither tab nor line switch' );
}

# No matches surfaces the explicit error.
{
    my $scandir = catdir( $home, 'scan_empty' );
    eval { run_open_file_command( paths => $reg, args => [ '--print', $scandir, 'nomatchzz' ] ) };
    like( $@, qr/^No files found/, 'run rejects unmatched searches' );
}

# Leave the temp tree so File::Temp cleanup can remove it.
chdir $orig_cwd or die "Unable to restore cwd to $orig_cwd: $!";

done_testing;

__END__

=pod

=head1 NAME

t/98-cli-openfile-coverage.t - branch and condition coverage for the open-file CLI helper

=head1 PURPOSE

This test drives every decision point in
C<Developer::Dashboard::CLI::OpenFile>, the library behind C<dashboard of> and
C<dashboard open-file>. It exercises direct path, C<file:line>, file-alias,
scoped-relative, Perl-module and Java-class resolution, the numbered chooser
flow, editor-command selection, and the Java source-archive and Maven download
lookups, including their guard, failure, and empty-input branches.

=head1 WHY IT EXISTS

The open-file helper carries an unusually dense set of fallback rules: regex
matching, module-to-file mapping, archive extraction, mirror-status handling,
and the print-versus-editor decision. Ordinary end-to-end use covers only the
common paths, leaving many guard clauses, short-circuit conditions, and error
returns untested. This file pins the remaining branch and condition sides so the
module holds at full Devel::Cover coverage and cannot silently regress a
defensive path.

=head1 WHEN TO USE

Use this file when changing how open-file resolves targets, ranks matches,
selects an editor, reads Java source jars, queries Maven Central, or decides
between printing and launching an editor. Re-run it whenever any of those
branches move.

=head1 HOW TO USE

Run C<perl -Ilib t/98-cli-openfile-coverage.t> or
C<prove -lv t/98-cli-openfile-coverage.t> while iterating. The test builds a
private temporary home, changes into it, and constructs registries against that
home so it never touches the developer's real runtime state. Network access is
replaced with in-process mocks of the user agent and the search/download
helpers.

=head1 WHAT USES IT

The repository test suite and the coverage gate run this file to keep the
open-file helper at full statement, subroutine, branch, and condition coverage.
Developers use it during test-driven changes to the open-file resolution logic.

=head1 EXAMPLES

Example 1:

  perl -Ilib t/98-cli-openfile-coverage.t

Run the open-file coverage checks by themselves.

Example 2:

  prove -lr t

Run this file inside the full repository suite before release.

=cut
