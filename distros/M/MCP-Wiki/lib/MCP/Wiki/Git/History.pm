package MCP::Wiki::Git::History;
# ABSTRACT: Section history tracking via heading paths
our $VERSION = '0.001';
use strict;
use warnings;
use Moo;
use Path::Tiny;
use Digest::SHA qw( sha256_hex );
use JSON::MaybeXS qw( decode_json encode_json );

has wiki_root => (
    is => 'ro',
    required => 1,
);

has repo => (
    is => 'lazy',
);

has history_file => (
    is => 'lazy',
);

sub _build_repo {
    my ($self) = @_;
    my $git_dir = $self->wiki_root . '/.git';

    die "Not a git repository: $git_dir" unless -d $git_dir;
    die "Git::Raw is required for git history" unless eval { require Git::Raw; 1 };

    return Git::Raw::Repository->open($self->wiki_root);
}

sub _build_history_file {
    my ($self) = @_;
    return Path::Tiny::path($self->wiki_root)->child('.mcp-wiki-history.json');
}

sub get_section_commits {
    my ($self, $page, $heading_path) = @_;

    my $repo = $self->repo;
    my $page_path = Path::Tiny::path($self->wiki_root)->child($page);

    die "File not found: $page" unless -e $page_path;

    # Walk commit history for this file
    my @commits;
    my $head = $repo->head->target;
    my $walker = $repo->walker;
    $walker->push($head->id);

    while (my $commit_id = $walker->next()) {
        my $commit = $repo->lookup($commit_id);
        my $tree = $commit->tree;

        # Try to find the file in this commit
        my $entry = $tree->entry($page);
        next unless $entry;

        # Get the blob content at this commit
        my $blob = $repo->lookup($entry->id);
        my $content = $blob->content;

        # Parse TOC to find if heading_path exists
        my $parser = $self->_get_parser;
        my @toc = $parser->parse_content($content);

        my ($heading_entry) = grep { $_->heading_path eq $heading_path } @toc;
        next unless $heading_entry;

        push @commits, {
            hash       => $commit_id->str,
            message    => $commit->message,
            author     => $commit->author->name,
            email      => $commit->author->email,
            time       => $commit->time,
            heading    => $heading_entry->heading,
            line_start => $heading_entry->line_start,
            line_end   => $heading_entry->line_end,
        };
    }

    return @commits;
}

sub get_section_content_at_commit {
    my ($self, $page, $heading_path, $commit_hash) = @_;

    my $repo = $self->repo;
    my $oid = Git::Raw::Oid->new($commit_hash);
    my $commit = $repo->lookup($oid);

    die "Commit not found: $commit_hash" unless $commit;

    my $tree = $commit->tree;
    my $entry = $tree->entry($page);
    die "File not in commit: $page" unless $entry;

    my $blob = $repo->lookup($entry->id);
    my $content = $blob->content;

    # Find the section
    my $parser = $self->_get_parser;
    my @toc = $parser->parse_content($content);

    my ($heading_entry) = grep { $_->heading_path eq $heading_path } @toc;
    die "Heading not found: $heading_path" unless $heading_entry;

    # Extract section content
    my @lines = split /\n/, $content;
    my $section = join("\n", @lines[$heading_entry->line_start - 1 .. $heading_entry->line_end - 1]);

    return {
        content     => $section,
        heading     => $heading_entry->heading,
        line_start  => $heading_entry->line_start,
        line_end    => $heading_entry->line_end,
    };
}

sub restore_section {
    my ($self, $page, $heading_path, $commit_hash, $opts) = @_;

    my $hist = $self->get_section_content_at_commit($page, $heading_path, $commit_hash);

    my $current_content = $opts->{current_content}
        or die "current_content required for restore";

    # Get current TOC and the section we want to restore
    my $parser = $self->_get_parser;
    my @current_toc = $parser->parse_content($current_content);

    my ($current_entry) = grep { $_->heading_path eq $heading_path } @current_toc;
    die "Heading not found in current content: $heading_path" unless $current_entry;

    # Build new content with restored section
    my @lines = split /\n/, $current_content;
    splice @lines, $current_entry->line_start - 1, $current_entry->line_end - $current_entry->line_start + 1,
        split /\n/, $hist->{content};

    my $new_content = join("\n", @lines);

    return {
        success       => 1,
        content       => $new_content,
        restored_from => $commit_hash,
        heading       => $heading_path,
    };
}

sub _get_parser {
    require MCP::Wiki::TOC::Parser;
    return 'MCP::Wiki::TOC::Parser';
}

sub auto_commit {
    my ($self, $file_path, $message, %opts) = @_;

    my $reason = $opts{reason};
    my $final_message = $reason // $message;

    my $repo = $self->repo;
    my $index = $repo->index;
    $index->read;

    # Stage the file
    $index->add($file_path);

    # Check if there are changes to commit
    my $head = $repo->head->target;
    my @diff_index = $index->files;
    unless (@diff_index) {
        return { success => 0, message => 'No changes to commit' };
    }

    $index->write;

    # Create commit
    my $author = Git::Raw::Signature->now('MCP::Wiki', 'mcp-wiki@localhost');
    my $commit_message = $reason ? "$final_message\n\nReason: $reason" : $final_message;

    my $new_commit = $repo->create_commit(
        $head->id,
        $author,
        $author,
        $commit_message,
        $head->tree->id,
        [$index->get($file_path)],
    );

    return {
        success => 1,
        hash    => $new_commit->id->str,
        message => $commit_message,
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MCP::Wiki::Git::History - Section history tracking via heading paths

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use MCP::Wiki::Git::History;

    my $git = MCP::Wiki::Git::History->new(wiki_root => '/path/to/wiki');

    # Get section history
    my @commits = $git->get_section_commits('page.md', 'Intro#Background');

    # Restore section from old commit
    my $result = $git->restore_section(
        'page.md',
        'Intro#Background',
        'abc123',
        { current_content => $current_md }
    );

=head1 DESCRIPTION

Tracks history of wiki sections via heading paths. When sections are
modified, the history records which commits touched which heading paths.

=cut

=head2 wiki_root

Root directory of the wiki (must be a git repo)

=head2 repo

Git::Raw repository object

=head2 history_file

Path to the history tracking file

=head2 get_section_commits

Get commit history for a section identified by heading_path.

    my @commits = $git->get_section_commits('page.md', 'Introduction#Background');

=head2 get_section_content_at_commit

Get the content of a section at a specific commit.

    my $content = $git->get_section_content_at_commit(
        'page.md',
        'Introduction#Background',
        'abc123def456'
    );

=head2 restore_section

Restore a section from a historical commit.

    my $result = $git->restore_section(
        'page.md',
        'Introduction#Background',
        'abc123def456',
        {
            current_content => $current_md,
            reason          => 'Fixing error',
        }
    );

Returns: { success => 1, content => $new_content, restored_from => $hash }
Or: { conflict => 1, content => $conflicted_content, base => $base, theirs => $theirs }

=head2 auto_commit

Auto-commit a change with optional reason.

    $git->auto_commit('page.md', 'Fix typo in introduction', reason => 'User reported typo');

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-mcp-wiki/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
