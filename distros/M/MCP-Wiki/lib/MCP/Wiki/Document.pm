package MCP::Wiki::Document;
# ABSTRACT: Wiki page document operations
our $VERSION = '0.001';
use strict;
use warnings;
use Moo;
use Path::Tiny;
use Digest::SHA qw( sha256_hex );
use MCP::Wiki::TOC::Parser;

has file_path => (
    is => 'ro',
    required => 1,
);

has wiki_root => (
    is => 'ro',
    required => 1,
);

sub content {
    my ($self) = @_;
    return Path::Tiny::path($self->file_path)->slurp_utf8;
}

sub get_toc {
    my ($self) = @_;
    return MCP::Wiki::TOC::Parser->parse_content($self->content);
}

sub get_paragraph {
    my ($self, $heading_path) = @_;
    my @entries = $self->get_toc;

    # Find entry by heading_path
    my ($entry) = grep { $_->heading_path eq $heading_path } @entries;
    return unless $entry;

    my @lines = split /\n/, $self->content;
    my $section = join("\n", @lines[$entry->line_start - 1 .. $entry->line_end - 1]);

    return {
        heading      => $entry->heading,
        heading_path => $entry->heading_path,
        content      => $section,
        line_start   => $entry->line_start,
        line_end     => $entry->line_end,
    };
}

sub set_paragraph {
    my ($self, $heading_path, $new_content) = @_;
    my @entries = $self->get_toc;

    my ($entry) = grep { $_->heading_path eq $heading_path } @entries;
    unless ($entry) {
        die "Heading not found: $heading_path";
    }

    my @lines = split /\n/, $self->content;

    # Replace lines in the section (excluding the heading line itself)
    my @new_lines = @lines;
    splice @new_lines, $entry->line_start, $entry->line_end - $entry->line_start + 1,
        split /\n/, $new_content;

    Path::Tiny::path($self->file_path)->spew_utf8(join("\n", @new_lines));

    return 1;
}

sub update_content_hash {
    my ($self) = @_;
    return sha256_hex($self->content);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MCP::Wiki::Document - Wiki page document operations

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use MCP::Wiki::Document;

    my $doc = MCP::Wiki::Document->new(
        path      => '/wiki/example.md',
        wiki_root => '/wiki',
    );

    my @toc = $doc->get_toc;
    my $para = $doc->get_paragraph('Introduction#Background');

=cut

=head2 file_path

Path to the markdown file

=head2 wiki_root

Root directory of the wiki (for path validation)

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
