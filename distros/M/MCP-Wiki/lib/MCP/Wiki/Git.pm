package MCP::Wiki::Git;
# ABSTRACT: Git integration for wiki page history
our $VERSION = '0.001';
use strict;
use warnings;
use Moo;
use Path::Tiny;

has wiki_root => (
    is => 'ro',
    required => 1,
);

has repo => (
    is => 'lazy',
);

sub _build_repo {
    my ($self) = @_;
    my $git_dir = $self->wiki_root . '/.git';

    die "Not a git repository: $git_dir" unless -d $git_dir;

    # Try to load Git::Raw
    eval { require Git::Raw };
    if ($@) {
        die "Git::Raw is required for git integration: $@";
    }

    return Git::Raw::Repository->open($self->wiki_root);
}

sub auto_commit {
    my ($self, $file_path, $message) = @_;

    my $repo = $self->repo;
    my $index = $repo->index;
    $index->read;

    $index->add($file_path);
    $index->write;

    my $author = Git::Raw::Signature->now('MCP::Wiki', 'mcp-wiki@localhost');
    $repo->create_commit(
        $repo->head->target->id,
        $author,
        $author,
        $message,
        $repo->head->target->tree->id,
        [$index->get($file_path)],
    );

    return 1;
}

sub get_head_hash {
    my ($self) = @_;
    return $self->repo->head->target->id;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MCP::Wiki::Git - Git integration for wiki page history

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use MCP::Wiki::Git;

    my $git = MCP::Wiki::Git->new(wiki_root => '/path/to/wiki');
    $git->auto_commit('example.md', 'Update example page');

=head1 DESCRIPTION

Git integration for wiki pages. Provides auto-commit functionality and
access to git history for section tracking.

Requires L<Git::Raw>.

=cut

=head2 wiki_root

Root directory of the wiki (must be a git repo)

=head2 repo

Path to the git repository

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
