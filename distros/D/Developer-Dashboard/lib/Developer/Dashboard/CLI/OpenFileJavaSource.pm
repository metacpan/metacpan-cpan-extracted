package Developer::Dashboard::CLI::OpenFileJavaSource;

use strict;
use warnings;

our $VERSION = '4.45';

use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use Digest::MD5 qw(md5_hex);
use Exporter 'import';
use File::Find ();
use File::Path qw(make_path);
use File::Spec;
use JSON::XS qw(decode_json);
use LWP::UserAgent;
use URI::Escape qw(uri_escape_utf8);

use Developer::Dashboard::CLI::OpenFileUtil qw(_unique_matches _unique_existing_dirs);

our @EXPORT_OK = qw(
    _java_archive_source_matches
    _candidate_java_source_archives
    _java_source_archive_roots
    _extract_java_sources_from_archive
    _matching_java_archive_entries
    _contained_cache_path
    _cached_archive_source_path
    _download_java_source_matches
    _maven_search_documents
    _download_maven_source_jar
);

# _java_archive_source_matches(%args)
# Resolves Java source files from local or downloaded source archives when no live .java file exists.
# The network fallback (Maven Central) only runs when the caller explicitly
# opts in via online => 1 (DD-914) - dashboard of otherwise looks like a
# local file-search command, and reaching the internet as an automatic side
# effect of a miss is a surprising thing for it to do silently. When offline
# and no local archive satisfies the lookup, a notice naming --online is
# printed to STDERR instead of either failing silently or making the call.
# Input: path registry object, root array reference, class name string, relative Java source path string, and online boolean.
# Output: ordered list of extracted Java source file paths.
sub _java_archive_source_matches {
    my (%args) = @_;
    my $paths    = $args{paths}    || die 'Missing path registry';
    my $roots    = $args{roots}    || [];
    my $name     = $args{name}     || return;
    my $relative = $args{relative} || return;
    my $online   = $args{online}   || 0;

    my @matches;
    for my $archive ( _candidate_java_source_archives( paths => $paths, roots => $roots ) ) {
        push @matches,
          _extract_java_sources_from_archive(
            paths    => $paths,
            archive  => $archive,
            relative => $relative,
          );
    }
    if ( !@matches && $online ) {
        push @matches,
          _download_java_source_matches(
            paths    => $paths,
            name     => $name,
            relative => $relative,
          );
    }
    elsif ( !@matches ) {
        print {*STDERR} "'$name' was not found locally; pass --online to search Maven Central.\n";
    }
    return _unique_matches(@matches);
}

# _candidate_java_source_archives(%args)
# Builds the ordered archive list used for Java source lookup outside direct filesystem source trees.
# Input: path registry object plus the root array reference already searched for plain files.
# Output: ordered list of candidate archive file paths.
sub _candidate_java_source_archives {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing path registry';
    my $roots = $args{roots} || [];
    my @archives;
    my %seen;

    for my $root ( _java_source_archive_roots( paths => $paths, roots => $roots ) ) {
        File::Find::find(
            {
                no_chdir => 1,
                wanted   => sub {
                    return if !-f $_;
                    my $path = $File::Find::name;
                    return if $path !~ /(?:-sources\.jar|-src\.jar|src\.zip|source\.zip|\.war|\.jar)\z/i;
                    return if $seen{$path}++;
                    push @archives, $path;
                },
            },
            $root,
        );
    }

    return @archives;
}

# _java_source_archive_roots(%args)
# Returns the filesystem roots that can contain Java source archives for open-file lookup.
# The incoming roots list (built by OpenFile.pm's _open_file_roots for
# Perl-module/general lookup) includes @INC, which structurally cannot
# contain Java source archives - kept in, it made every Java-class lookup
# miss walk the system Perl library tree via File::Find for no possible
# benefit (DD-916). @INC entries are excluded by identity here rather than
# re-deriving the general-purpose roots from scratch, so this stays correct
# if that list ever changes shape.
# Input: path registry object plus the current open-file roots array reference.
# Output: ordered list of existing directory path strings.
sub _java_source_archive_roots {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing path registry';
    my $roots = $args{roots} || [];
    my %is_inc = map { $_ => 1 } @INC;
    my @candidates = (
        ( grep { !$is_inc{$_} } @$roots ),
        File::Spec->catdir( $paths->home, '.m2', 'repository' ),
        File::Spec->catdir( $paths->home, '.gradle', 'caches' ),
        grep { defined && $_ ne '' } ( $ENV{JAVA_HOME}, $ENV{JDK_HOME} ),
    );

    return _unique_existing_dirs(@candidates);
}

# _extract_java_sources_from_archive(%args)
# Extracts matching Java source members from one zip-like archive into the dashboard cache tree.
# Input: path registry object, archive file path string, and relative Java source path string.
# Output: ordered list of extracted source file path strings.
sub _extract_java_sources_from_archive {
    my (%args) = @_;
    my $paths    = $args{paths}    || die 'Missing path registry';
    my $archive  = $args{archive}  || return;
    my $relative = $args{relative} || return;
    my $zip      = Archive::Zip->new();
    return if $zip->read($archive) != AZ_OK;

    my @matches;
    for my $entry ( _matching_java_archive_entries( zip => $zip, relative => $relative ) ) {
        my $member = $zip->memberNamed($entry) || next;

        # An archive member names its own destination, and archives reaching
        # here are third-party artifacts, so a member whose name climbs out of
        # the cache tree is dropped rather than written. Skipping keeps a
        # poisoned member from also denying the archive's legitimate members.
        my $target = _cached_archive_source_path(
            paths   => $paths,
            archive => $archive,
            entry   => $entry,
        ) or next;
        my ( $volume, $directories ) = File::Spec->splitpath($target);
        make_path( File::Spec->catpath( $volume, $directories, '' ) );
        open my $fh, '>', $target or die "Unable to write $target: $!";    # uncoverable branch true the target parent directory is created immediately above so the write cannot fail on the test host

        # contents() returns ($contents, $status) in list context, which print
        # imposes, so the member body must be taken in scalar context or the
        # status code is appended to every extracted source file.
        my ($contents) = $member->contents;
        print {$fh} $contents;
        close $fh;
        push @matches, $target;
    }

    return @matches;
}

# _matching_java_archive_entries(%args)
# Finds archive member names whose trailing path matches one requested Java source path.
# Input: Archive::Zip object and relative Java source path string.
# Output: ordered list of matching archive member path strings.
sub _matching_java_archive_entries {
    my (%args) = @_;
    my $zip      = $args{zip}      || return;
    my $relative = $args{relative} || return;
    my $suffix   = $relative;
    $suffix =~ s{\\}{/}g;

    my @entries;
    for my $member ( $zip->members ) {
        my $name = $member->fileName || next;
        next if $name !~ /(?:\A|\/)\Q$suffix\E\z/;
        push @entries, $name;
    }

    return @entries;
}

# _contained_cache_path($root, @segments)
# Resolves untrusted path segments below one cache root and refuses any result
# that escapes it. Segments arrive from archive member names and from remote
# Maven search documents, so a parent-directory run in them would otherwise
# steer a write to any location the user can reach. Resolution is lexical and
# never consults the filesystem, so the decision cannot change between the
# check and the write that follows it.
# Input: intended root directory path string plus untrusted path segments.
# Output: contained path string, or undef when the segments escape the root.
sub _contained_cache_path {
    my ( $root, @segments ) = @_;
    my @resolved;

    for my $part ( grep { $_ !~ m{\A\.?\z} } map { split m{[\\/]+}, $_ } @segments ) {
        if ( $part eq '..' ) {
            return if !@resolved;
            pop @resolved;
            next;
        }
        push @resolved, $part;
    }

    return if !@resolved;
    return File::Spec->catfile( $root, @resolved );
}

# _cached_archive_source_path(%args)
# Builds the stable cache location used for one extracted Java source member.
# Input: path registry object, archive file path string, and archive member path string.
# Output: extracted source file path string, or undef when the member escapes the cache.
sub _cached_archive_source_path {
    my (%args) = @_;
    my $paths   = $args{paths}   || die 'Missing path registry';
    my $archive = $args{archive} || die 'Missing archive path';
    my $entry   = $args{entry}   || die 'Missing archive entry';
    my $digest  = md5_hex( join "\0", $archive, $entry );

    return _contained_cache_path(
        File::Spec->catdir( $paths->cache_root, 'open-file', 'java-sources', $digest ),
        $entry,
    );
}

# _download_java_source_matches(%args)
# Downloads Maven source jars when local archive lookup cannot satisfy the requested Java class.
# Input: path registry object, fully qualified class name string, and relative Java source path string.
# Output: ordered list of extracted Java source file path strings.
sub _download_java_source_matches {
    my (%args) = @_;
    my $paths    = $args{paths}    || die 'Missing path registry';
    my $name     = $args{name}     || return;
    my $relative = $args{relative} || return;

    my @matches;
    for my $doc ( _maven_search_documents($name) ) {
        next if ref($doc) ne 'HASH';
        next if !grep { defined && $_ eq '-sources.jar' } @{ $doc->{ec} || [] };
        my $archive = _download_maven_source_jar( paths => $paths, doc => $doc ) or next;
        push @matches,
          _extract_java_sources_from_archive(
            paths    => $paths,
            archive  => $archive,
            relative => $relative,
          );
        last if @matches;
    }

    return @matches;
}

# _maven_search_documents($name)
# Queries Maven Central for one fully qualified Java class name.
# Input: fully qualified Java class name string.
# Output: ordered list of Maven search document hash references.
sub _maven_search_documents {
    my ($name) = @_;
    return if !defined $name || $name eq '';

    my $query = uri_escape_utf8(qq{fc:"$name"});
    my $url   = "https://search.maven.org/solrsearch/select?q=$query&rows=20&wt=json";
    my $ua    = LWP::UserAgent->new( timeout => 10 );
    my $res   = $ua->get($url);
    return if !$res->is_success;

    my $payload = eval { decode_json( $res->decoded_content ) };
    return if !$payload || ref($payload) ne 'HASH';
    return @{ $payload->{response}{docs} || [] };
}

# _download_maven_source_jar(%args)
# Downloads one Maven Central source jar into the dashboard cache tree when it is missing.
# Input: path registry object and one Maven search document hash reference.
# Output: local source-jar path string or undef on failure.
sub _download_maven_source_jar {
    my (%args) = @_;
    my $paths = $args{paths} || die 'Missing path registry';
    my $doc   = $args{doc}   || return;
    return if ref($doc) ne 'HASH';
    return if !defined $doc->{g} || !defined $doc->{a} || !defined $doc->{v};

    my $group_path = join '/', split /\./, $doc->{g};
    my $file       = "$doc->{a}-$doc->{v}-sources.jar";

    # The coordinates come from a remote search response, so the mirror target
    # is contained the same way an archive member name is: refuse before any
    # directory is created or any transfer is started.
    my $target = _contained_cache_path(
        File::Spec->catdir( $paths->cache_root, 'open-file', 'maven-sources' ),
        $group_path,
        $doc->{a},
        $doc->{v},
        $file,
    ) or return;
    return $target if -f $target;

    my ( $volume, $directories ) = File::Spec->splitpath($target);
    make_path( File::Spec->catpath( $volume, $directories, '' ) );

    my $url = join '/',
      'https://repo1.maven.org/maven2',
      $group_path,
      $doc->{a},
      $doc->{v},
      $file;
    my $ua  = LWP::UserAgent->new( timeout => 20 );
    my $res = $ua->mirror( $url, $target );
    return if !$res->is_success && $res->code != 304;
    return -f $target ? $target : undef;
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::CLI::OpenFileJavaSource - Java source-lookup support for dashboard of

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::OpenFileJavaSource qw(_java_archive_source_matches);
  my @matches = _java_archive_source_matches(
      paths => $paths, roots => \@roots, name => $class_name,
      relative => $relative_path, online => 0,
  );

=head1 DESCRIPTION

Extracted from C<Developer::Dashboard::CLI::OpenFile> (DD-918) to keep that
module under this project's 500-line-per-module guideline. Holds the entire
Java-class-to-source-file resolution subsystem: local source-archive
scanning, zip/jar extraction with path-containment protection, and the
opt-in Maven Central download fallback (DD-914).

=for comment FULL-POD-DOC START

=head1 PURPOSE

Resolves a fully qualified Java class name (e.g. C<javax.jws.WebService>) to
its source file, searching local C<.jar>/C<.war>/source-archive files first
and, only when explicitly permitted via C<online =E<gt> 1>, falling back to
downloading a matching source jar from Maven Central.

=head1 WHY IT EXISTS

C<Developer::Dashboard::CLI::OpenFile> mixed CLI dispatch, the interactive
chooser, scope-search ranking, and this entire archive/network subsystem in
one 961-line file. The Java-source-lookup machinery has no dependency on the
rest of that file's search logic beyond two small shared helpers
(C<_unique_matches>, C<_unique_existing_dirs>, both provided by
C<Developer::Dashboard::CLI::OpenFileUtil>), making it a natural, low-risk seam.

=head1 WHEN TO USE

Use this file when changing how Java source archives are located, how
zip/jar members are extracted and cache-contained, or how the Maven Central
download fallback behaves.

=head1 HOW TO USE

  use Developer::Dashboard::CLI::OpenFileJavaSource qw(_java_archive_source_matches);

Called by C<Developer::Dashboard::CLI::OpenFile>'s C<_named_source_matches>
once it has determined the requested name is a dotted Java class name (not
a Perl C<::>-separated module name) and no live C<.java> file already
satisfies it.

=head1 WHAT USES IT

C<Developer::Dashboard::CLI::OpenFile>'s C<_named_source_matches>, and this
module's own coverage tests.

=head1 EXAMPLES

  _java_archive_source_matches(
      paths    => $paths,
      roots    => \@roots,
      name     => 'javax.jws.WebService',
      relative => 'javax/jws/WebService.java',
      online   => 1,
  );

=for comment FULL-POD-DOC END

=cut
