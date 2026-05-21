package MCP::Wiki::Server;
# ABSTRACT: Main MCP server for wiki management
our $VERSION = '0.001';
use strict;
use warnings;
use Moo;
use MCP::Server;
use MCP::Wiki::Document;
use Path::Tiny;
use JSON::MaybeXS qw( to_json );
use Digest::SHA qw( sha256_hex );
use feature 'signatures';

has wiki_root => (
    is => 'ro',
    default => sub { '.' },
);

has use_git => (
    is => 'ro',
    default => 0,
);

has commit_reason_required => (
    is => 'ro',
    default => 0,
);

has server => (
    is => 'lazy',
    builder => '_build_server',
);

has _on_change_handlers => (
    is => 'ro',
    default => sub { [] },
);

has git_history => (
    is => 'lazy',
);

sub _build_git_history {
    my ($self) = @_;
    return unless $self->use_git;
    return unless eval { require Git::Raw; 1 };
    require MCP::Wiki::Git::History;
    return MCP::Wiki::Git::History->new(wiki_root => $self->wiki_root);
}

sub BUILD {
    my ($self) = @_;
    $self->_setup_tools;
}

sub _create_document {
    my ($self, $page, $root_dir) = @_;

    my $root = $root_dir // $self->wiki_root;
    my $wiki_root = Path::Tiny::path($root)->realpath
        or die "Invalid wiki_root: $root";

    # Security: ensure page path stays within wiki_root
    my $page_path = $wiki_root->child($page)->realpath;
    my $page_str = "$page_path";
    my $root_str = "$wiki_root";
    die "Path outside wiki root: $page" unless substr($page_str, 0, length($root_str)) eq $root_str;

    return MCP::Wiki::Document->new(
        file_path  => "$page_path",
        wiki_root  => "$wiki_root",
    );
}

sub _setup_tools {
    my ($self) = @_;

    my $server = $self->server;

    # Tool: list_pages
    $server->tool(
        name        => 'list_pages',
        description => 'List all wiki pages (markdown files) in the wiki root',
        input_schema => {
            type => 'object',
            properties => {
                root_dir => {
                    type => 'string',
                    description => 'Optional: override wiki root directory',
                },
            },
        },
        code => sub ($tool, $args) {
            my $wiki_root = Path::Tiny::path($args->{root_dir} // $self->wiki_root)->realpath
                or return $tool->text_result("Invalid wiki_root: $args->{root_dir}", 1);

            my @pages;
            my $iter = $wiki_root->iterator({ recurse => 1 });
            while (my $path = $iter->()) {
                if ($path->is_file && $path =~ /\.md$/i) {
                    my $rel = $path->relative($wiki_root);
                    push @pages, "$rel";
                }
            }

            return $tool->structured_result({
                pages => [sort @pages],
                count => scalar(@pages),
            });
        },
    );

    # Tool: get_toc
    $server->tool(
        name        => 'get_toc',
        description => 'Get table of contents for a wiki page',
        input_schema => {
            type => 'object',
            properties => {
                page => {
                    type => 'string',
                    description => 'Page name (relative path from wiki root)',
                },
                root_dir => {
                    type => 'string',
                    description => 'Optional: override wiki root directory',
                },
            },
            required => ['page'],
        },
        code => sub ($tool, $args) {
            my $doc = eval { $self->_create_document($args->{page}, $args->{root_dir}) };
            if ($@) {
                return $tool->text_result("Invalid page: $@", 1);
            }

            my @toc = $doc->get_toc;
            return $tool->structured_result({
                page => $args->{page},
                entries => [map { $_->as_hash } @toc],
            });
        },
    );

    # Tool: get_paragraph
    $server->tool(
        name        => 'get_paragraph',
        description => 'Get content under a specific heading path',
        input_schema => {
            type => 'object',
            properties => {
                page => {
                    type => 'string',
                    description => 'Page name',
                },
                heading_path => {
                    type => 'string',
                    description => 'Heading path (e.g. "Introduction#Background")',
                },
                root_dir => {
                    type => 'string',
                    description => 'Optional: override wiki root directory',
                },
            },
            required => ['page', 'heading_path'],
        },
        code => sub ($tool, $args) {
            my $doc = eval { $self->_create_document($args->{page}, $args->{root_dir}) };
            if ($@) {
                return $tool->text_result("Invalid page: $@", 1);
            }

            my $para = $doc->get_paragraph($args->{heading_path});
            unless ($para) {
                return $tool->text_result("Heading not found: $args->{heading_path}", 1);
            }

            return $tool->structured_result($para);
        },
    );

    # Tool: create_page
    $server->tool(
        name        => 'create_page',
        description => 'Create a new wiki page',
        input_schema => {
            type => 'object',
            properties => {
                page => {
                    type => 'string',
                    description => 'Page name (can include subdirectories)',
                },
                content => {
                    type => 'string',
                    description => 'Initial page content',
                },
                root_dir => {
                    type => 'string',
                    description => 'Optional: override wiki root directory',
                },
            },
            required => ['page'],
        },
        code => sub ($tool, $args) {
            my $wiki_root = Path::Tiny::path($args->{root_dir} // $self->wiki_root)->realpath
                or return $tool->text_result("Invalid wiki_root", 1);

            my $page_path = $wiki_root->child($args->{page})->realpath;
            unless (index("$page_path", "$wiki_root") == 0) {
                return $tool->text_result("Invalid page path", 1);
            }

            if (-e $page_path) {
                return $tool->text_result("Page already exists: $args->{page}", 1);
            }

            $page_path->parent->mkpath;
            $page_path->spew_utf8($args->{content} // "# $args->{page}\n");

            $self->_fire_on_change({
                type   => 'create',
                page   => $args->{page},
                reason => $args->{reason},
            });

            return $tool->structured_result({
                success => 1,
                page    => $args->{page},
            });
        },
    );

    # Tool: update_paragraph
    $server->tool(
        name        => 'update_paragraph',
        description => 'Update content under a heading',
        input_schema => {
            type => 'object',
            properties => {
                page => {
                    type => 'string',
                    description => 'Page name',
                },
                heading_path => {
                    type => 'string',
                    description => 'Heading path to update',
                },
                content => {
                    type => 'string',
                    description => 'New content for the section',
                },
                reason => {
                    type => 'string',
                    description => 'Reason for the change (used as git commit message if git is enabled)',
                },
                root_dir => {
                    type => 'string',
                    description => 'Optional: override wiki root directory',
                },
            },
            required => ['page', 'heading_path', 'content'],
        },
        code => sub ($tool, $args) {
            my $doc = eval { $self->_create_document($args->{page}, $args->{root_dir}) };
            if ($@) {
                return $tool->text_result("Invalid page: $@", 1);
            }

            eval { $doc->set_paragraph($args->{heading_path}, $args->{content}) };
            if ($@) {
                return $tool->text_result("Update failed: $@", 1);
            }

            $self->_fire_on_change({
                type   => 'update',
                page   => $args->{page},
                heading_path => $args->{heading_path},
                reason => $args->{reason},
            });

            return $tool->structured_result({
                success => 1,
                page    => $args->{page},
                heading_path => $args->{heading_path},
            });
        },
    );

    # Tool: rename_page
    $server->tool(
        name        => 'rename_page',
        description => 'Rename or move a wiki page',
        input_schema => {
            type => 'object',
            properties => {
                from => {
                    type => 'string',
                    description => 'Current page name',
                },
                to => {
                    type => 'string',
                    description => 'New page name',
                },
                root_dir => {
                    type => 'string',
                    description => 'Optional: override wiki root directory',
                },
            },
            required => ['from', 'to'],
        },
        code => sub ($tool, $args) {
            my $wiki_root = Path::Tiny::path($args->{root_dir} // $self->wiki_root)->realpath;

            my $from_path = $wiki_root->child($args->{from})->realpath;
            my $to_path = $wiki_root->child($args->{to})->realpath;

            unless (index("$from_path", "$wiki_root") == 0 && index("$to_path", "$wiki_root") == 0) {
                return $tool->text_result("Invalid path", 1);
            }

            unless (-e $from_path) {
                return $tool->text_result("Page not found: $args->{from}", 1);
            }

            if (-e $to_path) {
                return $tool->text_result("Target already exists: $args->{to}", 1);
            }

            $to_path->parent->mkpath;
            $from_path->move($to_path);

            $self->_fire_on_change({
                type   => 'rename',
                from   => $args->{from},
                to     => $args->{to},
            });

            return $tool->structured_result({
                success => 1,
                from    => $args->{from},
                to      => $args->{to},
            });
        },
    );

    # Tool: delete_page
    $server->tool(
        name        => 'delete_page',
        description => 'Delete a wiki page',
        input_schema => {
            type => 'object',
            properties => {
                page => {
                    type => 'string',
                    description => 'Page name to delete',
                },
                root_dir => {
                    type => 'string',
                    description => 'Optional: override wiki root directory',
                },
            },
            required => ['page'],
        },
        code => sub ($tool, $args) {
            my $wiki_root = Path::Tiny::path($args->{root_dir} // $self->wiki_root)->realpath;

            my $page_path = $wiki_root->child($args->{page})->realpath;
            unless (index("$page_path", "$wiki_root") == 0) {
                return $tool->text_result("Invalid path", 1);
            }

            unless (-e $page_path) {
                return $tool->text_result("Page not found: $args->{page}", 1);
            }

            $page_path->remove;

            $self->_fire_on_change({
                type => 'delete',
                page => $args->{page},
            });

            return $tool->structured_result({
                success => 1,
                page    => $args->{page},
            });
        },
    );

    # Tool: get_section_history
    $server->tool(
        name        => 'get_section_history',
        description => 'Get commit history for a section identified by heading path',
        input_schema => {
            type => 'object',
            properties => {
                page => {
                    type => 'string',
                    description => 'Page name',
                },
                heading_path => {
                    type => 'string',
                    description => 'Heading path (e.g. "Introduction#Background")',
                },
                root_dir => {
                    type => 'string',
                    description => 'Optional: override wiki root directory',
                },
            },
            required => ['page', 'heading_path'],
        },
        code => sub ($tool, $args) {
            my $git = $self->git_history;
            unless ($git) {
                return $tool->text_result("Git history not available (git may not be enabled)", 1);
            }

            my @commits = $git->get_section_commits($args->{page}, $args->{heading_path});
            return $tool->structured_result({
                page         => $args->{page},
                heading_path => $args->{heading_path},
                commits      => \@commits,
                count        => scalar(@commits),
            });
        },
    );

    # Tool: restore_section
    $server->tool(
        name        => 'restore_section',
        description => 'Restore a section from a historical commit',
        input_schema => {
            type => 'object',
            properties => {
                page => {
                    type => 'string',
                    description => 'Page name',
                },
                heading_path => {
                    type => 'string',
                    description => 'Heading path to restore',
                },
                commit_hash => {
                    type => 'string',
                    description => 'Git commit hash to restore from',
                },
                reason => {
                    type => 'string',
                    description => 'Reason for the restore (used as git commit message)',
                },
                root_dir => {
                    type => 'string',
                    description => 'Optional: override wiki root directory',
                },
            },
            required => ['page', 'heading_path', 'commit_hash'],
        },
        code => sub ($tool, $args) {
            my $git = $self->git_history;
            unless ($git) {
                return $tool->text_result("Git history not available (git may not be enabled)", 1);
            }

            my $doc = eval { $self->_create_document($args->{page}, $args->{root_dir}) };
            if ($@) {
                return $tool->text_result("Invalid page: $@", 1);
            }

            my $current_content = $doc->content;
            my $result = $git->restore_section(
                $args->{page},
                $args->{heading_path},
                $args->{commit_hash},
                { current_content => $current_content }
            );

            if ($result->{conflict}) {
                return $tool->structured_result($result);
            }

            # Apply the restored content
            eval { $doc->set_paragraph($args->{heading_path}, $result->{content}) };
            if ($@) {
                return $tool->text_result("Restore failed: $@", 1);
            }

            $self->_fire_on_change({
                type         => 'restore',
                page         => $args->{page},
                heading_path => $args->{heading_path},
                commit_hash  => $args->{commit_hash},
                reason       => $args->{reason},
            });

            return $tool->structured_result({
                success       => 1,
                page          => $args->{page},
                heading_path  => $args->{heading_path},
                restored_from => $result->{restored_from},
            });
        },
    );
}

sub _build_server {
    my ($self) = @_;
    return MCP::Server->new(name => 'MCP-Wiki');
}

sub on_change {
    my ($self, $handler) = @_;
    push @{$self->_on_change_handlers}, $handler;
    return $self;
}

sub _fire_on_change {
    my ($self, $event) = @_;

    # Auto-commit via git if enabled
    if ($self->use_git && $event->{type} ne 'restore') {
        my $git = $self->git_history;
        if ($git) {
            my $message = $self->_commit_message_for_event($event);
            my $reason = $event->{reason};
            eval {
                $git->auto_commit(
                    $event->{page},
                    $message,
                    (defined $reason ? (reason => $reason) : ()),
                );
            };
            warn "Git auto-commit error: $@" if $@;
        }
    }

    # Call user handlers
    for my $handler (@{$self->_on_change_handlers}) {
        eval { $handler->($event) };
        warn "on_change error: $@" if $@;
    }
}

sub _commit_message_for_event {
    my ($self, $event) = @_;
    my %messages = (
        create  => "Created page",
        update  => "Updated page",
        rename  => "Renamed page",
        delete  => "Deleted page",
    );
    my $type = $event->{type} // 'unknown';
    my $page = $event->{page} // '';
    my $heading = $event->{heading_path} // '';
    if ($heading) {
        return "$messages{$type}: $page ($heading)";
    }
    return "$messages{$type}: $page";
}

sub to_stdio {
    my ($self) = @_;
    $self->server->to_stdio;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MCP::Wiki::Server - Main MCP server for wiki management

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use MCP::Wiki::Server;

    my $server = MCP::Wiki::Server->new(
        wiki_root => '/path/to/wiki',
        use_git   => 1,
    );

    $server->on_change(sub {
        my $ev = shift;
        if ($ev->{type} eq 'update') {
            say "Page updated: $ev->{page}";
        }
    });

    $server->to_stdio;

=cut

=head2 wiki_root

Root directory for wiki pages. Defaults to current directory.

=head2 use_git

Enable git auto-commit on changes. Default: 0

=head2 commit_reason_required

Require a reason for commits. Default: 0

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
