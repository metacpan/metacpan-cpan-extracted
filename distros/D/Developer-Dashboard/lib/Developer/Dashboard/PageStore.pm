package Developer::Dashboard::PageStore;
$Developer::Dashboard::PageStore::VERSION = '0.72';
use strict;
use warnings;

use File::Spec;
use File::Basename qw(basename);
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
    return File::Spec->catfile( $self->{paths}->dashboards_root, $id );
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
    open my $fh, '>', $file or die "Unable to save $file: $!";
    print {$fh} $page->canonical_instruction;
    close $fh;
    return $file;
}

# load_saved_page($id)
# Loads a saved page definition from disk.
# Input: page id string.
# Output: Developer::Dashboard::PageDocument object.
sub load_saved_page {
    my ( $self, $id ) = @_;
    my $file = $self->page_file($id);
    die "Page '$id' not found" if !-f $file;
    open my $fh, '<', $file or die "Unable to read $file: $!";
    local $/;
    my $page = Developer::Dashboard::PageDocument->from_instruction(<$fh>);
    $page->{id} ||= $id;
    $page->{meta}{source_kind} = 'saved';
    return $page;
}

# read_saved_entry($id)
# Reads a raw saved bookmark entry from disk without parsing it.
# Input: page id string.
# Output: raw file content string.
sub read_saved_entry {
    my ( $self, $id ) = @_;
    my $file = $self->page_file($id);
    die "Page '$id' not found" if !-f $file;
    open my $fh, '<', $file or die "Unable to read $file: $!";
    local $/;
    return <$fh>;
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
    my $root = $self->{paths}->dashboards_root;
    opendir my $dh, $root or return;

    my @ids;
    while ( my $entry = readdir $dh ) {
        next if $entry eq '.' || $entry eq '..';
        next if -d File::Spec->catfile( $root, $entry );
        my $ok = eval { $self->load_saved_page($entry); 1 };
        push @ids, $entry if $ok;
    }
    closedir $dh;

    return sort @ids;
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
        open my $out, '>', $target or die "Unable to save $target: $!";
        print {$out} $page->canonical_instruction;
        close $out;
        unlink $file or die "Unable to remove $file: $!";
        push @migrated, { from => $entry, id => $id, file => $target };
    }
    closedir $dh;
    return \@migrated;
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

=cut
