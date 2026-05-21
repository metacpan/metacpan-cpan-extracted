package MCP::Wiki::TOC::Entry;
# ABSTRACT: Single TOC entry with heading path and line range
our $VERSION = '0.001';
use Moo;
use Types::Standard qw( Int Str Maybe );

has level => (
    is => 'ro',
    required => 1,
);

has heading => (
    is => 'ro',
    required => 1,
);

has anchor => (
    is => 'ro',
    required => 1,
);

has heading_path => (
    is => 'ro',
    required => 1,
);

has line_start => (
    is => 'ro',
    required => 1,
);

has line_end => (
    is => 'ro',
    required => 1,
);

has content_preview => (
    is => 'ro',
    required => 1,
);

has char_count => (
    is => 'ro',
    required => 1,
);

sub as_hash {
    my ($self) = @_;
    return {
        level           => $self->level,
        heading         => $self->heading,
        anchor          => $self->anchor,
        heading_path    => $self->heading_path,
        line_start      => $self->line_start,
        line_end        => $self->line_end,
        content_preview=> $self->content_preview,
        char_count      => $self->char_count,
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MCP::Wiki::TOC::Entry - Single TOC entry with heading path and line range

=head1 VERSION

version 0.001

=head2 level

Heading level (1-6)

=head2 heading

The heading text without the # prefix

=head2 anchor

URL-safe anchor (derived from heading)

=head2 heading_path

Full path of nested headings (e.g. "Introduction#Background")

=head2 line_start

Starting line number (1-indexed, inclusive)

=head2 line_end

Ending line number (1-indexed, inclusive)

=head2 content_preview

First ~100 chars of the section content

=head2 char_count

Total character count of the section

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
