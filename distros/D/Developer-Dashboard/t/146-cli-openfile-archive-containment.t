#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Spec::Functions qw(catdir catfile);
use Cwd qw(getcwd abs_path);
use File::Find ();
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use HTTP::Response;
use LWP::UserAgent;

use lib 'lib';

use Developer::Dashboard::CLI::OpenFile;
use Developer::Dashboard::PathRegistry;

my $PKG = 'Developer::Dashboard::CLI::OpenFile';

# oc($function_name, @args)
# Calls one private OpenFile helper by name, preserving list context.
# Input: helper function name string plus its argument list.
# Output: whatever the underlying helper returns.
sub oc {
    my $fn = shift;
    no strict 'refs';
    return &{"${PKG}::${fn}"}(@_);
}

# write_jar($path, \%entries)
# Builds a zip archive whose member names are stored verbatim, including any
# parent-directory segments, so the extractor under test receives exactly the
# member name a hostile artifact would carry.
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

# climb($levels)
# Builds a leading run of parent-directory segments for a hostile member name.
# Input: number of levels to climb.
# Output: member-name prefix string ending in a slash.
sub climb {
    my ($levels) = @_;
    return join '', ('../') x $levels;
}

# --- Hermetic runtime rooted in a private temp home -------------------------
my $orig_cwd = getcwd();
my $home     = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $reg = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home );

# The cache root is <home>/.developer-dashboard/cache, so the per-archive digest
# directory <cache>/open-file/java-sources/<digest> sits five levels below the
# temp home. Climbing exactly five levels therefore lands a hostile member in a
# sibling of the runtime layer: decisively outside the cache root, yet still
# inside the temp tree this file owns, so a leaked write is cleaned up rather
# than dropped on the real filesystem.
my $ESCAPE_DIRNAME = 'dd498-escape-target';
my $escaped_root   = catdir( $home, $ESCAPE_DIRNAME );
my $escaped_file   = catfile( $escaped_root, 'com', 'example', 'Foo.java' );
my $hostile_member = climb(5) . "$ESCAPE_DIRNAME/com/example/Foo.java";

my $java_cache    = catdir( $reg->cache_root, 'open-file', 'java-sources' );
my $good_relative = catfile( 'com', 'example', 'Foo.java' );

my $MAVEN_MARKER = 'dd498-maven-escape';

# contains_path($parent, $child)
# Reports whether a resolved child path lies inside a resolved parent directory.
# Input: parent directory path string and existing child path string.
# Output: 1 when contained, 0 otherwise.
sub contains_path {
    my ( $parent, $child ) = @_;
    my $p = abs_path($parent) or return 0;
    my $c = abs_path($child)  or return 0;
    return index( $c, $p . '/' ) == 0 ? 1 : 0;
}

# marker_paths_under($root, $marker)
# Collects every path below one root whose name is the given marker, so a leaked
# write is found wherever the code chose to put it rather than only where the
# test predicted.
# Input: root directory path string and marker basename string.
# Output: sorted list of matching path strings.
sub marker_paths_under {
    my ( $root, $marker ) = @_;
    my @hits;
    File::Find::find(
        {   no_chdir => 1,
            wanted   => sub {
                push @hits, $File::Find::name if ( File::Spec->splitpath($File::Find::name) )[2] eq $marker;
            },
        },
        $root,
    );
    return sort @hits;
}

# ---------------------------------------------------------------------------
# AC-1: a hostile member name must not write outside the cache root
# ---------------------------------------------------------------------------
{
    my $jar = catfile( $home, 'hostile-sources.jar' );
    write_jar( $jar, { $hostile_member => "PWNED\n" } );

    my @extracted = oc(
        '_extract_java_sources_from_archive',
        paths    => $reg,
        archive  => $jar,
        relative => $good_relative,
    );

    ok( !-e $escaped_file, 'hostile archive member writes no file outside the cache root' );
    ok( !-d $escaped_root, 'hostile archive member creates no directory outside the cache root' );
    is_deeply( \@extracted, [], 'hostile archive member is skipped rather than returned' );
}

# ---------------------------------------------------------------------------
# AC-2: ordinary members still extract, at both depths the matcher accepts
# ---------------------------------------------------------------------------
{
    my $jar = catfile( $home, 'plain-sources.jar' );
    write_jar( $jar, { 'com/example/Foo.java' => "class Foo {}\n" } );

    my @extracted = oc(
        '_extract_java_sources_from_archive',
        paths    => $reg,
        archive  => $jar,
        relative => $good_relative,
    );

    is( scalar @extracted, 1, 'a plain member is still extracted' );
    ok( -f $extracted[0], 'the extracted plain member exists on disk' );
    ok( contains_path( $java_cache, $extracted[0] ), 'the plain member lands inside the java-sources cache' );

    open my $fh, '<', $extracted[0] or die "Unable to read $extracted[0]: $!";
    my $body = do { local $/; <$fh> };
    close $fh or die "Unable to close $extracted[0]: $!";
    is( $body, "class Foo {}\n", 'the extracted plain member keeps its contents' );
}
{
    my $jar = catfile( $home, 'nested-sources.jar' );
    write_jar( $jar, { 'sources/com/example/Foo.java' => "class Nested {}\n" } );

    my @extracted = oc(
        '_extract_java_sources_from_archive',
        paths    => $reg,
        archive  => $jar,
        relative => $good_relative,
    );

    is( scalar @extracted, 1, 'a nested but contained member is still extracted' );
    ok( contains_path( $java_cache, $extracted[0] ), 'the nested member lands inside the java-sources cache' );
}

# ---------------------------------------------------------------------------
# AC-3: a poisoned archive must not deny service to its legitimate member
# ---------------------------------------------------------------------------
{
    my $jar = catfile( $home, 'mixed-sources.jar' );
    write_jar(
        $jar,
        {   $hostile_member        => "PWNED\n",
            'com/example/Foo.java' => "class Good {}\n",
        },
    );

    my @extracted = oc(
        '_extract_java_sources_from_archive',
        paths    => $reg,
        archive  => $jar,
        relative => $good_relative,
    );

    is( scalar @extracted, 1, 'only the contained member of a poisoned archive is returned' );
    ok( !-e $escaped_file, 'the poisoned member of a mixed archive still writes nothing outside the cache' );
}

# ---------------------------------------------------------------------------
# _cached_archive_source_path refuses the escape instead of returning a path
# ---------------------------------------------------------------------------
{
    is(
        oc( '_cached_archive_source_path', paths => $reg, archive => 'a.jar', entry => $hostile_member ),
        undef,
        'an escaping entry yields no cache path',
    );
    is(
        oc( '_cached_archive_source_path', paths => $reg, archive => 'a.jar', entry => '.' ),
        undef,
        'an entry naming only the current directory yields no cache path',
    );
    is(
        oc( '_cached_archive_source_path', paths => $reg, archive => 'a.jar', entry => 'com/..' ),
        undef,
        'an entry that cancels back to the root yields no cache path',
    );

    my $contained = oc( '_cached_archive_source_path', paths => $reg, archive => 'a.jar', entry => 'com/example/Foo.java' );
    ok( defined $contained, 'a contained entry still yields a cache path' );

    # A leading separator, a redundant current-directory segment and an inner
    # parent segment that stays below the root are all normalised rather than
    # refused, so ordinary archives keep working. The digest directory differs
    # per entry name, so only the resolved tail is comparable.
    my $normalised = oc( '_cached_archive_source_path', paths => $reg, archive => 'a.jar', entry => '/com/./example/other/../Foo.java' );
    ok( defined $normalised, 'leading, redundant and inner-cancelling segments still yield a cache path' );
    my $tail = catfile( 'com', 'example', 'Foo.java' );
    like( $normalised, qr{\Q$tail\E\z}, 'those segments normalise to the same contained tail' );
    is( index( $normalised, $java_cache . '/' ), 0, 'the normalised path stays inside the java-sources cache' );
}

# ---------------------------------------------------------------------------
# AC-4: Maven coordinates that escape the cache must not mirror anything
# ---------------------------------------------------------------------------
{
    my $mirrored = 0;
    no warnings 'redefine';
    local *LWP::UserAgent::mirror = sub {
        $mirrored++;
        return HTTP::Response->new( 200, 'OK', [], '' );
    };

    is(
        oc( '_download_maven_source_jar', paths => $reg, doc => { g => 'com.ok', a => climb(6) . $MAVEN_MARKER, v => '1.0' } ),
        undef,
        'an escaping artifact coordinate yields no jar',
    );
    is(
        oc( '_download_maven_source_jar', paths => $reg, doc => { g => 'com.ok', a => 'art', v => climb(6) . $MAVEN_MARKER } ),
        undef,
        'an escaping version coordinate yields no jar',
    );
    is( $mirrored, 0, 'no download is attempted for escaping Maven coordinates' );

    # Asserting a single predicted landing directory would be a check aimed at
    # a path the code may never have chosen, so the whole temp home is swept
    # for the marker instead.
    is_deeply( [ marker_paths_under( $home, $MAVEN_MARKER ) ], [], 'escaping Maven coordinates create nothing anywhere under the home' );
}

chdir $orig_cwd or die "Unable to chdir back to $orig_cwd: $!";

done_testing();

__END__

=pod

=head1 NAME

t/146-cli-openfile-archive-containment.t - DD-498 Zip Slip containment for open-file archive extraction

=head1 PURPOSE

Pins the containment guarantee that C<dashboard open-file> owes when it reads a
Java source archive it did not author. The command falls back to searching
C<~/.m2/repository>, C<~/.gradle/caches> and the configured JDK roots for
C<*.jar>, C<*.war> and C<src.zip> members, and downloads a C<-sources.jar> from
Maven Central when local lookup fails, so every member name reaching the
extractor is third-party input.

=head1 WHAT IS COVERED

The extraction destination is derived from the archive member's own name. This
file asserts that a member name carrying parent-directory segments writes
nothing outside the dashboard cache root and creates no directory there, that
the escaping member is skipped rather than made fatal, and that an archive
holding both a hostile and a legitimate member still yields the legitimate one.
It also asserts the positive path is undamaged: a plain member and a member
nested under a source prefix both extract into the java-sources cache with
their contents intact. Finally it covers the same containment obligation on the
Maven download target, whose path is built from artifact and version fields
supplied by a remote search response, asserting that escaping coordinates
return no jar and trigger no transfer.

=head1 WHY IT EXISTS

Without the guard, a single poisoned member name turns opening a class into an
arbitrary file write with attacker-supplied contents at an attacker-chosen
location, which on a developer machine means overwriting real source consumed
by the next build. The negative assertions here climb exactly as far as the
cache root is deep, so they land in a sibling of the runtime layer inside this
file's own temp home: far enough that a write which escapes cannot be mistaken
for one the cache root legitimately owns, and near enough that the leak is
cleaned up rather than dropped on the real filesystem. The content assertion
exists for a second reason: it caught C<contents> being called in the list
context C<print> imposes, which appended the Archive::Zip status code to every
extracted source file.

=head1 WHEN TO USE

Run this file when changing anything in C<_extract_java_sources_from_archive>,
C<_cached_archive_source_path>, C<_contained_cache_path> or
C<_download_maven_source_jar>, and whenever a new caller starts building a
filesystem path out of an archive member name or a remote coordinate. A change
that widens what the member-name matcher accepts belongs here too, because the
matcher is what decides which member names reach the extractor at all.

=head1 HOW TO USE

  PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/146-cli-openfile-archive-containment.t

The file is hermetic: it roots a temp home, chdirs into it and builds every
fixture archive there, so it needs no Maven cache, no JDK and no network. The
Maven assertions replace C<LWP::UserAgent::mirror> with a counting stub, so a
regression that starts a transfer is caught by the counter rather than by a
timeout.

=head1 WHAT USES IT

The full suite runs it as an ordinary test file, and the all-metric coverage
gate counts it toward the branch and condition coverage of
C<Developer::Dashboard::CLI::OpenFile>, whose containment helper has no other
caller-visible entry point.

=head1 EXAMPLES

The shape of the input this file defends against is one archive member whose
name climbs out of the cache tree:

  my $zip = Archive::Zip->new;
  $zip->addString( "PWNED\n", '../../../../../escape/com/example/Foo.java' );
  $zip->writeToFileNamed($jar);

Extracting that archive for the class C<com.example.Foo> must return an empty
list and leave no file at the escaped location, while the same call against a
member named C<com/example/Foo.java> must still return one path inside
C<< <cache_root>/open-file/java-sources/ >> holding the member's exact bytes.

=cut
