package Developer::Dashboard::PageStore;

use strict;
use warnings;

our $VERSION = '6.06';
use utf8;

use Encode qw(decode FB_CROAK FB_DEFAULT);
use Cwd qw(abs_path);
use Fcntl qw(:DEFAULT :mode);
use File::Find ();
use File::Spec;
use File::Basename qw(basename dirname);
use URI::Escape qw(uri_escape);
use Time::HiRes ();
use bytes ();

use Developer::Dashboard::Codec qw(encode_payload decode_payload);
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::Platform qw(is_windows);
use Developer::Dashboard::PathsRegistryArg qw(require_paths_arg);

# _nofollow_flag()
# Resolves the no-follow open flag: O_NOFOLLOW where the platform provides the
# macro, otherwise 0 so path-based fallback opens still work on such runtimes.
# Looked up at call time so a platform without the macro can be modelled.
# Input: none.
# Output: integer open flag.
sub _nofollow_flag {
    my $flag = eval { Fcntl->can('O_NOFOLLOW')->() };
    return $flag ? $flag : 0;
}

my $NOFOLLOW = _nofollow_flag();

# new(%args)
# Constructs the page persistence and token transport store.
# Input: paths object.
# Output: Developer::Dashboard::PageStore object.
sub new {
    my ( $class, %args ) = @_;
    my $paths = require_paths_arg(%args);
    return bless { paths => $paths }, $class;
}

# page_file($id)
# Resolves the on-disk file path for a saved page id.
# Input: page id string.
# Output: page file path string.
sub page_file {
    my ( $self, $id ) = @_;
    die 'Missing page id' if !defined $id || $id eq '';
    return File::Spec->catfile( $self->{paths}->dashboards_root, $self->_validated_page_id($id) );
}

# save_page($page)
# Persists a page document as canonical instruction text.
# Input: page hash reference or Developer::Dashboard::PageDocument object.
# Output: written page file path.
sub save_page {
    my ( $self, $page ) = @_;
    if ( ref($page) ne 'Developer::Dashboard::PageDocument' ) {
        $page = Developer::Dashboard::PageDocument->from_hash($page);
    }

    my $id = $page->as_hash->{id} || die 'Saved pages require an id';
    my $file = $self->page_file($id);
    my $fh = $self->_open_saved_page_for_write(
        $self->{paths}->dashboards_root,
        $self->_validated_page_id($id),
        create_dirs => 1,
    );
    print {$fh} $page->canonical_instruction;
    close $fh;
    $self->{paths}->secure_file_permissions($file);
    return $file;
}

# load_saved_page($id)
# Loads a saved page definition from disk.
# Input: page id string.
# Output: Developer::Dashboard::PageDocument object.
sub load_saved_page {
    my ( $self, $id ) = @_;
    my ( $file, $root ) = $self->_existing_page_file($id);
    die "Page '$id' not found" if !$file;
    my $instruction = $self->_read_saved_instruction( $file, root => $root, id => $id );
    my $page = $self->_load_page_instruction( $instruction, id => $id );
    $page->{id} ||= $id;
    $page->{meta}{source_kind} = 'saved';
    $page->{meta}{raw_instruction} = $instruction;
    return $page;
}

# load_nav_fragment($id)
# Loads a discovered saved nav fragment. Literal HTML returns directly without
# allocating a page document; TT and structured instructions retain the normal
# parsing path and saved-page metadata. Reads still use the no-follow secure
# open boundary, and every call observes current file contents.
# Input: nav/<name>.tt id discovered from a dashboards layer and optional root
# from the scanned configured layers.
# Output: { kind => 'literal', body => $text }, { kind => 'page', page => the
# document }, or undef if the fragment disappeared before opening.
sub load_nav_fragment {
    my ( $self, $id, %args ) = @_;
    my $normalized_id = $self->_validated_page_id($id);
    die 'Invalid nav fragment id' if $normalized_id !~ m{\Anav/.+\.tt\z};

    my ( $file, $root );
    my @initial_stat;
    if ( defined $args{root} ) {
        my $validated_roots = $self->{_validated_nav_roots};
        if ( ref($validated_roots) ne 'HASH' || !$validated_roots->{ $args{root} } ) {
            my @roots = ref( $self->{_page_roots_snapshot} ) eq 'ARRAY'
              ? @{ $self->{_page_roots_snapshot} }
              : $self->{paths}->dashboards_roots;
            die 'Invalid nav fragment root' if !grep { defined $_ && $_ eq $args{root} } @roots;
            $self->{_validated_nav_roots}{ $args{root} } = 1
              if ref($validated_roots) eq 'HASH';
        }
        $root = $args{root};
        $file = File::Spec->catfile( $root, $normalized_id );
        @initial_stat = Time::HiRes::lstat($file);
        return if !@initial_stat;
        die 'Invalid page path' if S_ISLNK( $initial_stat[2] );
        return if !S_ISREG( $initial_stat[2] );
    }
    else {
        ( $file, $root ) = $self->_existing_page_file($normalized_id);
        return if !$file;
        @initial_stat = Time::HiRes::lstat($file);
        die 'Invalid page path' if @initial_stat && S_ISLNK( $initial_stat[2] );
        die 'Invalid page path' if @initial_stat && !S_ISREG( $initial_stat[2] );
    }

    my $initial_fingerprint = @initial_stat
      ? join( "\0", @initial_stat[ 0, 1, 2, 7, 9, 10 ] )
      : undef;
    my $cache = $self->{_nav_fragment_cache};
    if ( defined $initial_fingerprint && ref($cache) eq 'HASH'
        && ref( $cache->{entries} ) eq 'HASH'
        && exists $cache->{entries}{$file} )
    {
        my $cached = $cache->{entries}{$file};
        if ( ref($cached) eq 'HASH'
          && defined $cached->{fingerprint}
          && $cached->{fingerprint} eq $initial_fingerprint )
        {
            $self->_assert_page_path_contained( $file, root => $root );
            return { kind => 'literal', body => $cached->{body} };
        }
    }

    my $instruction = $self->_read_saved_instruction( $file, root => $root, id => $normalized_id );
    my $looks_like_nav = $self->_looks_like_raw_nav_fragment($instruction);
    my $has_instruction_header = $instruction =~ /^===\s*[A-Z][A-Z0-9.]*\s*===\s*$/m
      || $instruction =~ /^(?:TITLE|ICON|BOOKMARK|STASH|NOTE|HEAD|HTML|CODE\d+)\s*:/m;

    if ( $looks_like_nav && !$has_instruction_header ) {
        if ( index( $instruction, '[%' ) < 0 ) {
            my @final_stat = Time::HiRes::lstat($file);
            my $final_fingerprint = @final_stat && S_ISREG( $final_stat[2] )
              ? join( "\0", @final_stat[ 0, 1, 2, 7, 9, 10 ] )
              : undef;
            $self->_cache_literal_nav_fragment( $file, $final_fingerprint, $instruction )
              if defined $initial_fingerprint && defined $final_fingerprint
              && $initial_fingerprint eq $final_fingerprint
              && bytes::length($instruction) <= 262144;
            return { kind => 'literal', body => $instruction };
        }
        my $page = $self->_raw_nav_fragment_page( id => $normalized_id, instruction => $instruction );
        $page->{meta}{source_kind} = 'saved';
        $page->{meta}{raw_instruction} = $instruction;
        return { kind => 'page', page => $page };
    }

    my $page = $self->_load_page_instruction( $instruction, id => $normalized_id );
    $page->{id} = $normalized_id if !$page->{id};
    $page->{meta}{source_kind} = 'saved';
    $page->{meta}{raw_instruction} = $instruction;
    return { kind => 'page', page => $page };
}

# _cache_literal_nav_fragment($file, $fingerprint, $body)
# Stores a small verified literal nav body in a bounded per-PageStore cache.
# Input: file path, matching high-resolution lstat fingerprint, and decoded HTML.
# Output: true after insertion or an explicit false for an unusable cache.
sub _cache_literal_nav_fragment {
    my ( $self, $file, $fingerprint, $body ) = @_;
    return 0 if !defined $file || !defined $fingerprint || !defined $body;

    my $cache = $self->{_nav_fragment_cache};
    if ( ref($cache) ne 'HASH' ) {
        $cache = $self->{_nav_fragment_cache} = { bytes => 0, entries => {}, order => [] };
    }
    return 0
      if ref( $cache->{entries} ) ne 'HASH'
      || ref( $cache->{order} ) ne 'ARRAY'
      || !defined $cache->{bytes}
      || $cache->{bytes} !~ /\A\d+\z/;
    if ( exists $cache->{entries}{$file} ) {
        my $old_entry = $cache->{entries}{$file};
        my $old_body = ref($old_entry) eq 'HASH' ? ( $old_entry->{body} || '' ) : '';
        $cache->{bytes} -= bytes::length($old_body);
        @{ $cache->{order} } = grep { $_ ne $file } @{ $cache->{order} };
    }
    $cache->{entries}{$file} = { fingerprint => $fingerprint, body => $body };
    $cache->{bytes} += bytes::length($body);
    push @{ $cache->{order} }, $file;

    while ( @{ $cache->{order} } > 128 || $cache->{bytes} > 4_194_304 ) {
        my $evict = shift @{ $cache->{order} };
        next if !exists $cache->{entries}{$evict};
        my $old_entry = $cache->{entries}{$evict};
        my $old_body = ref($old_entry) eq 'HASH' ? ( $old_entry->{body} || '' ) : '';
        $cache->{bytes} -= bytes::length($old_body);
        delete $cache->{entries}{$evict};
    }
    return 1;
}

# read_saved_entry($id)
# Reads a raw saved bookmark entry from disk without parsing it.
# Input: page id string.
# Output: raw file content string.
sub read_saved_entry {
    my ( $self, $id ) = @_;
    my ( $file, $root ) = $self->_existing_page_file($id);
    die "Page '$id' not found" if !$file;
    return $self->_read_saved_instruction( $file, root => $root, id => $id );
}

# load_transient_page($token)
# Loads a transient page from an encoded token.
# Input: encoded transient page token.
# Output: Developer::Dashboard::PageDocument object.
sub load_transient_page {
    my ( $self, $token ) = @_;
    my $instruction = decode_payload($token);
    my $page = Developer::Dashboard::PageDocument->from_instruction($instruction);
    $page->{meta}{source_kind} = 'transient';
    return $page;
}

# encode_page($page)
# Serializes and encodes a page definition for transient transport.
# Input: page hash reference or Developer::Dashboard::PageDocument object.
# Output: encoded token string.
sub encode_page {
    my ( $self, $page ) = @_;
    if ( ref($page) ne 'Developer::Dashboard::PageDocument' ) {
        $page = Developer::Dashboard::PageDocument->from_hash($page);
    }
    my $raw_instruction = $page->{meta}{raw_instruction};
    return encode_payload($raw_instruction)
      if defined $raw_instruction && $raw_instruction ne '';
    return encode_payload( $page->canonical_instruction );
}

# editable_url($page)
# Builds the transient edit URL for a page.
# Input: page hash reference or document object.
# Output: relative URL string.
sub editable_url {
    my ( $self, $page ) = @_;
    return '/?token=' . uri_escape( $self->encode_page($page) );
}

# render_url($page)
# Builds the transient render URL for a page.
# Input: page hash reference or document object.
# Output: relative URL string.
sub render_url {
    my ( $self, $page ) = @_;
    return '/?mode=render&token=' . uri_escape( $self->encode_page($page) );
}

# source_url($page)
# Builds the transient source URL for a page.
# Input: page hash reference or document object.
# Output: relative URL string.
sub source_url {
    my ( $self, $page ) = @_;
    return '/?mode=source&token=' . uri_escape( $self->encode_page($page) );
}

# list_saved_pages()
# Lists valid saved page ids from disk.
# Input: none.
# Output: sorted list of page id strings.
sub list_saved_pages {
    my ($self) = @_;
    my %ids;
    for my $root ( reverse $self->{paths}->dashboards_roots ) {
        for my $entry ( $self->_saved_page_entries_for_root($root) ) {
            my $id = $entry->{id};
            next if !defined $id || $id eq '';
            my $ok = eval {
                my $instruction = $self->_read_saved_instruction( $entry->{file}, root => $root, id => $id );
                $self->_load_page_instruction( $instruction, id => $id );
                1;
            };
            next if !$ok;
            $ids{$id} = 1;
        }
    }

    return sort keys %ids;
}

# migrate_legacy_json_pages()
# Converts old JSON page files into canonical bookmark instruction files.
# Input: none.
# Output: array reference of migrated id/file hashes.
sub migrate_legacy_json_pages {
    my ($self) = @_;
    my $root = $self->{paths}->dashboards_root;
    opendir my $dh, $root or return [];

    my @migrated;
    while ( my $entry = readdir $dh ) {
        next if $entry eq '.' || $entry eq '..';
        next if $entry !~ /\.json\z/;
        my $file = File::Spec->catfile( $root, $entry );
        next if -d $file;
        next if -l $file;
        next if !eval { $self->_assert_page_path_contained( $file, root => $root ); 1 };
        my $fh = eval { $self->_open_saved_page_for_read( $root, $entry ) } or next;
        local $/;
        my $raw = <$fh>;
        close $fh;
        my $page = eval { Developer::Dashboard::PageDocument->from_json($raw) } or next;
        my $id = $page->as_hash->{id} || basename( $entry, '.json' );
        $page->{id} = $id;
        my $normalized_id = eval { $self->_validated_page_id($id) };
        next if !defined $normalized_id;
        my $target = File::Spec->catfile( $root, $normalized_id );
        my $out = $self->_open_saved_page_for_write( $root, $normalized_id, create_dirs => 1 );
        print {$out} $page->canonical_instruction;
        close $out;
        $self->{paths}->secure_file_permissions($target);
        unlink $file or die "Unable to remove $file: $!";
        push @migrated, { from => $entry, id => $id, file => $target };
    }
    closedir $dh;
    return \@migrated;
}

# _page_file_candidates($id)
# Returns candidate bookmark files for a page id in lookup order.
# Within a web request, all saved-page lookups share that request's fresh
# ordered root snapshot; direct calls continue to resolve roots on every call.
# Input: page id string.
# Output: ordered list of hash references with root and file keys.
sub _page_file_candidates {
    my ( $self, $id ) = @_;
    my $normalized = $self->_validated_page_id($id);
    my @roots;
    if ( exists $self->{_page_roots_snapshot} ) {
        if ( ref( $self->{_page_roots_snapshot} ) eq 'ARRAY' ) {
            @roots = @{ $self->{_page_roots_snapshot} };
        }
        else {
            @roots = $self->{paths}->dashboards_roots;
            $self->{_page_roots_snapshot} = [@roots];
        }
    }
    else {
        @roots = $self->{paths}->dashboards_roots;
    }
    return map {
        my $root = $_;
        { root => $root, file => File::Spec->catfile( $root, $normalized ) }
    } @roots;
}

# _validated_page_id($id)
# Validates one bookmark id before it is joined to a dashboards root. Canonical
# flat ASCII names bypass the general prefix and path-component normalization.
# Input: page id string, optionally already prefixed with /app/.
# Output: relative bookmark id with no current/parent-directory components.
sub _validated_page_id {
    my ( $self, $id ) = @_;
    return $id
      if defined $id && !ref($id)
      && $id =~ m{\Anav/[A-Za-z0-9_-][A-Za-z0-9_.-]*\.tt\z}
      && index( $id, '..' ) < 0;
    return $id
      if defined $id && !ref($id)
      && $id =~ m{\A[A-Za-z0-9_-][A-Za-z0-9_.-]*\z};

    my $normalized = $self->_normalized_page_id($id);
    die 'Invalid page id' if $normalized eq '';
    die 'Invalid page id' if $normalized =~ /\A[A-Za-z]:/;
    die 'Invalid page id' if grep { $_ eq '' || $_ eq '.' || $_ eq '..' } split m{[\\/]}, $normalized, -1;
    return $normalized;
}

# _assert_page_path_contained($file, %args)
# Ensures a page path's resolved target or nearest existing ancestor remains
# beneath one configured dashboards root before a read or write follows it.
# Windows-only case and separator normalization preserves POSIX backslash names.
# Dashboard requests share only a stable root realpath within one request;
# every candidate path is still resolved and checked on every access.
# Input: candidate file path plus optional for_write boolean.
# Output: true, or dies with Invalid page path when containment is violated.
sub _assert_page_path_contained {
    my ( $self, $file, %args ) = @_;
    die 'Invalid page path' if !defined $file || $file eq '';

    my @roots = exists $args{root} ? ( $args{root} ) : $self->{paths}->dashboards_roots;
    for my $root (@roots) {
        next if !defined $root || $root eq '';
        my $scope = $self->{_page_containment_root_realpaths};
        my $root_real;
        if ( ref($scope) eq 'HASH' ) {
            $root_real = exists $scope->{$root} ? $scope->{$root} : ( $scope->{$root} = abs_path($root) );
        }
        else {
            $root_real = abs_path($root);
        }
        next if !defined $root_real;

        my $probe = $file;
        if ( $args{for_write} && !-e $probe && !-l $probe ) {
            while ( !-e $probe && !-l $probe ) {
                $probe = dirname($probe);
            }
        }
        my $probe_real = abs_path($probe);
        next if !defined $probe_real;
        my ( $probe_cmp, $root_cmp ) = ( $probe_real, $root_real );
        if ( is_windows() ) {
            $probe_cmp = lc $probe_cmp;
            $root_cmp  = lc $root_cmp;
            $probe_cmp =~ s{\\}{/}g;
            $root_cmp  =~ s{\\}{/}g;
        }
        return 1 if $probe_cmp eq $root_cmp;
        return 1 if index( $probe_cmp, $root_cmp . '/' ) == 0;
    }

    die 'Invalid page path';
}

# _open_saved_page_for_read($root, $id)
# Opens one saved page through no-follow directory descriptors where openat is
# available, preventing a validated pathname from being swapped to a symlink.
# Input: dashboards root and validated relative page id.
# Output: readable filehandle.
sub _open_saved_page_for_read {
    my ( $self, $root, $id ) = @_;
    return $self->_open_saved_page_at( root => $root, id => $id, flags => O_RDONLY );
}

# _open_saved_page_for_write($root, $id)
# Opens one saved page for replacement without following symlinks in any path
# component when openat is available.
# Input: dashboards root and validated relative page id.
# Output: writable filehandle.
sub _open_saved_page_for_write {
    my ( $self, $root, $id, %args ) = @_;
    return $self->_open_saved_page_at(
        root  => $root,
        id    => $id,
        flags => O_WRONLY | O_CREAT | O_TRUNC,
        mode  => 0600,
        create_dirs => $args{create_dirs} ? 1 : 0,
    );
}

# _open_saved_page_at(%args)
# Opens a validated page id beneath a dashboards root, asserting the resolved
# path stays contained in that root and refusing to follow a symlinked leaf.
# One path on every platform: a capability-dependent variant would mean two
# installs of the same release protecting their users differently.
# Input: root, id, open flags, and optional creation mode.
# Output: Perl filehandle bound to the opened file.
sub _open_saved_page_at {
    my ( $self, %args ) = @_;
    my $root = $args{root} || die 'Invalid page path';
    my $id = $self->_validated_page_id( $args{id} );

    my $file = File::Spec->catfile( $root, $id );
    $self->_assert_page_path_contained( $file, root => $root, for_write => ( $args{flags} & O_WRONLY ? 1 : 0 ) );
    $self->{paths}->ensure_dir( dirname($file) ) if $args{create_dirs} && !-d dirname($file);
    my $fh;
    if ( $args{flags} & O_WRONLY ) {
        sysopen $fh, $file, $args{flags} | $NOFOLLOW, $args{mode} || 0600 or die 'Invalid page path';
    }
    else {
        sysopen $fh, $file, $args{flags} | $NOFOLLOW or die 'Invalid page path';
        binmode $fh, ':raw';
    }
    return $fh;
}

# _normalized_page_id($id)
# Normalizes one saved bookmark id for on-disk lookup and persistence.
# Input: page id string, optionally already prefixed with /app/.
# Output: relative bookmark id string without a leading /app/ or slash.
sub _normalized_page_id {
    my ( $self, $id ) = @_;
    $id = '' if !defined $id;
    $id =~ s/^\s+//;
    $id =~ s/\s+$//;
    $id =~ s{\A/+app/+}{};
    $id =~ s{\A/+}{};
    return $id;
}

# _existing_page_file($id)
# Resolves the first existing bookmark file path for a page id. Containment is
# enforced once at the secure open boundary, not repeated during this lookup.
# Input: page id string.
# Output: file path plus its owning root in list context, the file path alone
# in scalar context, or nothing when the page is missing.
sub _existing_page_file {
    my ( $self, $id ) = @_;
    for my $candidate ( $self->_page_file_candidates($id) ) {
        my $file = $candidate->{file};
        next if !-f $file;
        return wantarray ? ( $file, $candidate->{root} ) : $file;
    }
    return;
}

# _load_page_file($file, %args)
# Loads and parses one bookmark file from disk, with raw nav/*.tt fragment fallback.
# Input: bookmark file path string plus optional saved-page id.
# Output: Developer::Dashboard::PageDocument object.
sub _load_page_file {
    my ( $self, $file, %args ) = @_;
    my $instruction = $self->_read_saved_instruction($file);
    return $self->_load_page_instruction( $instruction, %args );
}

# _load_page_instruction($instruction, %args)
# Parses saved instruction text into a page document, wrapping raw nav/*.tt
# fragments directly when they contain no bookmark-section header. The direct
# path avoids invoking the full legacy parser for ordinary HTML/TT fragments.
# Input: decoded instruction text string plus optional saved-page id.
# Output: Developer::Dashboard::PageDocument object.
sub _load_page_instruction {
    my ( $self, $instruction, %args ) = @_;
    my $id = $args{id} || '';
    my $is_nav_fragment = $id =~ m{\Anav/.+\.tt\z};
    my $looks_like_nav_fragment = $is_nav_fragment && $self->_looks_like_raw_nav_fragment($instruction);
    if ($looks_like_nav_fragment) {
        my $has_instruction_header = $instruction =~ /^===\s*[A-Z][A-Z0-9.]*\s*===\s*$/m
          || $instruction =~ /^(?:TITLE|ICON|BOOKMARK|STASH|NOTE|HEAD|HTML|CODE\d+)\s*:/m;
        return $self->_raw_nav_fragment_page( id => $id, instruction => $instruction )
          if !$has_instruction_header;
    }

    my $page = eval { Developer::Dashboard::PageDocument->from_instruction($instruction) };
    return $page if $page;

    if ($looks_like_nav_fragment) {
        return $self->_raw_nav_fragment_page(
            id          => $id,
            instruction => $instruction,
        );
    }

    die $@;
}

# _raw_nav_fragment_page(%args)
# Wraps a raw nav/*.tt Template Toolkit fragment file as a renderable page document.
# Input: saved nav id and raw instruction text string.
# Output: Developer::Dashboard::PageDocument object.
sub _raw_nav_fragment_page {
    my ( $self, %args ) = @_;
    my $id = $args{id} || die 'Missing raw nav fragment id';
    my $instruction = defined $args{instruction} ? $args{instruction} : '';
    return Developer::Dashboard::PageDocument->new(
        id     => $id,
        title  => basename($id),
        layout => { body => $instruction },
        meta   => { source_format => 'raw-nav-tt' },
    );
}

# _looks_like_raw_nav_fragment($instruction)
# Decides whether one nav/*.tt file is a real raw TT/HTML fragment instead of junk text.
# Input: raw saved file text string.
# Output: boolean true when the file looks like raw TT/HTML nav content.
sub _looks_like_raw_nav_fragment {
    my ( $self, $instruction ) = @_;
    return 0 if !defined $instruction || $instruction eq '';
    return 1 if $instruction =~ /\[%/;
    return 1 if $instruction =~ /<\s*[A-Za-z!\/][^>]*>/;
    return 0;
}

# _read_saved_instruction($file, %args)
# Reads one saved bookmark file and normalizes older-invalid UTF-8 bytes; with
# a root and id it opens through the symlink-refusing descriptor path.
# Input: bookmark file path string plus optional owning root and page id.
# Output: decoded instruction text string that is safe to emit as UTF-8 HTML/text.
sub _read_saved_instruction {
    my ( $self, $file, %args ) = @_;
    my $fh = exists $args{root}
      ? $self->_open_saved_page_for_read( $args{root}, $args{id} )
      : do {
          open my $direct_fh, '<:raw', $file or die "Unable to read $file: $!";
          $direct_fh;
      };
    local $/;
    my $raw = <$fh>;
    close $fh or die "Unable to close $file: $!";
    my $text = eval { decode( 'UTF-8', $raw, FB_CROAK ) } || decode( 'UTF-8', $raw, FB_DEFAULT );
    return $self->_normalize_legacy_icon_markup($text);
}

# _normalize_legacy_icon_markup($text)
# Repairs browser-visible icon placeholders left behind by malformed older bookmark bytes.
# A U+FFFD precheck bypasses all repair expressions for the common case.
# Input: decoded bookmark instruction text string.
# Output: normalized instruction text string with stable fallback glyphs in icon HTML contexts.
sub _normalize_legacy_icon_markup {
    my ( $self, $text ) = @_;
    return '' if !defined $text;
    return $text if index( $text, "\x{FFFD}" ) < 0;
    $text =~ s/\x{1F9D1}\x{FFFD}\x{1F4BB}/\x{1F9D1}\x{200D}\x{1F4BB}/g;
    $text =~ s{(<h2>)\x{FFFD}(\s+)}{$1◈$2}g;
    $text =~ s{(<span\s+class="icon">)[^<]*\x{FFFD}[^<]*(</span>)}{$1🏷️$2}g;
    return $text;
}

# _saved_page_entries_for_root($root)
# Recursively lists bookmark file entries under one saved-page root.
# Input: bookmark root directory path string.
# Output: list of hash references with id and file keys.
sub _saved_page_entries_for_root {
    my ( $self, $root ) = @_;
    return if !defined $root || !-d $root;

    my @entries;
    File::Find::find(
        {
            no_chdir => 1,
            wanted   => sub {
                return if !-f $_;
                return if -l $File::Find::name;
                return if !eval { $self->_assert_page_path_contained( $File::Find::name, root => $root ); 1 };
                my $rel = File::Spec->abs2rel( $File::Find::name, $root );
                $rel =~ s{\\}{/}g;
                push @entries, {
                    id   => $rel,
                    file => $File::Find::name,
                };
            },
        },
        $root,
    );

    return @entries;
}

1;

__END__

=head1 NAME

Developer::Dashboard::PageStore - page persistence and token transport

=head1 SYNOPSIS

  my $store = Developer::Dashboard::PageStore->new(paths => $paths);
  my $page  = $store->load_saved_page('welcome');

=head1 DESCRIPTION

This module persists saved page instruction documents and handles transient
encoded page transport. Its nav-fragment loader can return unchanged literal
HTML without constructing a page object, while dynamic or structured nav files
still use the canonical parser and renderer. The bounded in-memory cache uses
high-resolution file identity and timestamps; it does not cache dynamic
Template Toolkit output and each cache lookup checks that the file is still a
regular file under a configured dashboards layer.

=head1 METHODS

=head2 new, page_file, save_page, load_saved_page, load_nav_fragment, load_transient_page, encode_page, editable_url, render_url, source_url, list_saved_pages, migrate_legacy_json_pages

Manage saved and transient pages.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module persists and lists saved dashboard pages under the runtime dashboards tree. It turns page IDs into concrete bookmark files, writes edited pages back to disk, and provides the saved-page inventory used by the browser and CLI page commands.

Canonical single-segment ASCII ids use a narrow validation fast path that
avoids general prefix normalization and path splitting. Prefixed, nested,
Unicode, whitespace-bearing, and reference ids still follow the full
normalization and validation path; traversal checks and secure path containment
remain in force for every file operation.

=head1 WHY IT EXISTS

It exists because saved bookmark storage needs one owner for file layout, ID validation, overwrite behavior, and page listing. That keeps the editor, CLI page helpers, and seeded-page bootstrap all talking to the same store semantics.

=head1 WHEN TO USE

Use this file when changing saved page file layout, bookmark ID handling, list ordering, or any feature that loads or saves pages under F<dashboards/>.

=head1 HOW TO USE

Construct it with the active paths object, then use the page load/save/list methods instead of reading the dashboards directory directly. Let this module enforce the saved-page storage contract.

The web application uses C<load_nav_fragment> for discovered C<nav/*.tt>
files. It supplies the scanned root so the store can avoid searching every
layer, while the store still validates the root, checks the current file
identity, and uses the secure no-follow open when content is not cached. A
literal HTML fragment is returned as a body string; fragments with Template
Toolkit directives and structured bookmark files are returned as page
documents for normal request-time rendering.

=head1 WHAT USES IT

It is used by CLI page commands, web edit/source/render routes, seed bootstrap flows, and tests that verify saved bookmark persistence.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::PageStore -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/07-core-units.t t/21-refactor-coverage.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.

Example 5:

  my $fragment = $store->load_nav_fragment('nav/status.tt', root => $dashboard_root);

Use this for a discovered layered nav file. A literal fragment returns
C<{ kind =E<gt> 'literal', body =E<gt> ... }>; a dynamic or structured file
returns C<{ kind =E<gt> 'page', page =E<gt> $document }>, and a file removed
between inventory and load returns C<undef>.


=for comment FULL-POD-DOC END

=cut
