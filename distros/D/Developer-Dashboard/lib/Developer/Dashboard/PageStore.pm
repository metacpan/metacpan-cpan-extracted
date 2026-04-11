package Developer::Dashboard::PageStore;

use strict;
use warnings;

our $VERSION = '2.26';
use utf8;

use Encode qw(decode FB_CROAK FB_DEFAULT);
use File::Find ();
use File::Spec;
use File::Basename qw(basename dirname);
use File::Path qw(make_path);
use URI::Escape qw(uri_escape);

use Developer::Dashboard::Codec qw(encode_payload decode_payload);
use Developer::Dashboard::PageDocument;

# new(%args)
# Constructs the page persistence and token transport store.
# Input: paths object.
# Output: Developer::Dashboard::PageStore object.
sub new {
    my ( $class, %args ) = @_;
    my $paths = $args{paths} || die 'Missing paths registry';
    return bless { paths => $paths }, $class;
}

# page_file($id)
# Resolves the on-disk file path for a saved page id.
# Input: page id string.
# Output: page file path string.
sub page_file {
    my ( $self, $id ) = @_;
    die 'Missing page id' if !defined $id || $id eq '';
    return File::Spec->catfile( $self->{paths}->dashboards_root, $self->_normalized_page_id($id) );
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
    my $dir = dirname($file);
    $self->{paths}->ensure_dir($dir);
    open my $fh, '>', $file or die "Unable to save $file: $!";
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
    my $file = $self->_existing_page_file($id);
    die "Page '$id' not found" if !$file;
    my $page = $self->_load_page_file( $file, id => $id );
    $page->{id} ||= $id;
    $page->{meta}{source_kind} = 'saved';
    $page->{meta}{raw_instruction} = $self->_read_saved_instruction($file);
    return $page;
}

# read_saved_entry($id)
# Reads a raw saved bookmark entry from disk without parsing it.
# Input: page id string.
# Output: raw file content string.
sub read_saved_entry {
    my ( $self, $id ) = @_;
    my $file = $self->_existing_page_file($id);
    die "Page '$id' not found" if !$file;
    return $self->_read_saved_instruction($file);
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
            my $ok = eval { $self->_load_page_file( $entry->{file}, id => $id ); 1 };
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
        open my $fh, '<', $file or next;
        local $/;
        my $raw = <$fh>;
        close $fh;
        my $page = eval { Developer::Dashboard::PageDocument->from_json($raw) } or next;
        my $id = $page->as_hash->{id} || basename( $entry, '.json' );
        $page->{id} = $id;
        my $target = $self->page_file($id);
        $self->{paths}->ensure_dir( dirname($target) );
        open my $out, '>', $target or die "Unable to save $target: $!";
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
# Returns candidate bookmark file paths for a page id in lookup order.
# Input: page id string.
# Output: ordered list of bookmark file path strings.
sub _page_file_candidates {
    my ( $self, $id ) = @_;
    my $normalized = $self->_normalized_page_id($id);
    return map { File::Spec->catfile( $_, $normalized ) } $self->{paths}->dashboards_roots;
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
# Resolves the first existing bookmark file path for a page id.
# Input: page id string.
# Output: bookmark file path string or undef when missing.
sub _existing_page_file {
    my ( $self, $id ) = @_;
    for my $file ( $self->_page_file_candidates($id) ) {
        return $file if -f $file;
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
    my $page = eval { Developer::Dashboard::PageDocument->from_instruction($instruction) };
    return $page if $page;

    my $id = $args{id} || '';
    if ( $id =~ m{\Anav/.+\.tt\z} && $self->_looks_like_raw_nav_fragment($instruction) ) {
        return $self->_raw_nav_fragment_page(
            id          => $id,
            instruction => $instruction,
        );
    }

    die( $@ || "Unable to load bookmark file $file" );
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

# _read_saved_instruction($file)
# Reads one saved bookmark file and normalizes older-invalid UTF-8 bytes.
# Input: bookmark file path string.
# Output: decoded instruction text string that is safe to emit as UTF-8 HTML/text.
sub _read_saved_instruction {
    my ( $self, $file ) = @_;
    open my $fh, '<:raw', $file or die "Unable to read $file: $!";
    local $/;
    my $raw = <$fh>;
    close $fh or die "Unable to close $file: $!";
    return '' if !defined $raw;
    my $text = eval { decode( 'UTF-8', $raw, FB_CROAK ) } || decode( 'UTF-8', $raw, FB_DEFAULT );
    return $self->_normalize_legacy_icon_markup($text);
}

# _normalize_legacy_icon_markup($text)
# Repairs browser-visible icon placeholders left behind by malformed older bookmark bytes.
# Input: decoded bookmark instruction text string.
# Output: normalized instruction text string with stable fallback glyphs in icon HTML contexts.
sub _normalize_legacy_icon_markup {
    my ( $self, $text ) = @_;
    return '' if !defined $text;
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
encoded page transport.

=head1 METHODS

=head2 new, page_file, save_page, load_saved_page, load_transient_page, encode_page, editable_url, render_url, source_url, list_saved_pages, migrate_legacy_json_pages

Manage saved and transient pages.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module persists and lists saved dashboard pages under the runtime dashboards tree. It turns page IDs into concrete bookmark files, writes edited pages back to disk, and provides the saved-page inventory used by the browser and CLI page commands.

=head1 WHY IT EXISTS

It exists because saved bookmark storage needs one owner for file layout, ID validation, overwrite behavior, and page listing. That keeps the editor, CLI page helpers, and seeded-page bootstrap all talking to the same store semantics.

=head1 WHEN TO USE

Use this file when changing saved page file layout, bookmark ID handling, list ordering, or any feature that loads or saves pages under F<dashboards/>.

=head1 HOW TO USE

Construct it with the active paths object, then use the page load/save/list methods instead of reading the dashboards directory directly. Let this module enforce the saved-page storage contract.

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


=for comment FULL-POD-DOC END

=cut
