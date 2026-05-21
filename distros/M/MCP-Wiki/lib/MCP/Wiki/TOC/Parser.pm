package MCP::Wiki::TOC::Parser;
# ABSTRACT: Markdown TOC extraction - pure Perl implementation
our $VERSION = '0.001';
use strict;
use warnings;
use MCP::Wiki::TOC::Entry;
use Path::Tiny;


my $IN_CODE_BLOCK;

sub parse_file {
    my ($class, $file_path) = @_;
    my $content = Path::Tiny::path($file_path)->slurp_utf8;
    return $class->parse_content($content);
}

sub parse_content {
    my ($class, $content) = @_;

    $IN_CODE_BLOCK = 0;
    my @lines = split /\n/, $content;
    my @headings;  # [line_number, level, heading_text]

    for my $i (0 .. $#lines) {
        my $line = $lines[$i];

        # Check for code block boundaries
        if ($line =~ /^\s*```/) {
            $IN_CODE_BLOCK = !$IN_CODE_BLOCK;
            next;
        }
        next if $IN_CODE_BLOCK;

        # Skip indented code (4+ spaces at line start)
        next if $line =~ /^    /;

        # Match ATX-style headings: 1-6 # characters
        if ($line =~ /^(#{1,6})\s+(.+?)\s*#*\s*$/) {
            my $level = length($1);  # number of # chars
            my $heading_text = $2;

            push @headings, [$i + 1, $level, $heading_text];  # 1-indexed line
        }
    }

    # Convert to TOC entries with line ranges
    my @entries;
    for my $i (0 .. $#headings) {
        my ($line_start, $level, $heading) = @{$headings[$i]};

        # Determine line_end: next heading - 1, or end of content
        my $line_end;
        if ($i < $#headings) {
            $line_end = $headings[$i + 1][0] - 1;
        } else {
            $line_end = scalar(@lines);
        }

        # Build heading_path (ancestor headings)
        my $heading_path = $class->_build_heading_path(\@headings, $i);

        # Content preview
        my ($preview, $char_count) = $class->_extract_section(\@lines, $line_start, $line_end);

        # URL-safe anchor
        my $anchor = $class->_make_anchor($heading);

        push @entries, MCP::Wiki::TOC::Entry->new(
            level           => $level,
            heading         => $heading,
            anchor          => $anchor,
            heading_path    => $heading_path,
            line_start      => $line_start,
            line_end        => $line_end,
            content_preview => $preview,
            char_count      => $char_count,
        );
    }

    return @entries;
}

sub _build_heading_path {
    my ($class, $headings, $index) = @_;
    my @path;

    for my $i (0 .. $index) {
        my $level = $headings->[$i][1];
        my $heading = $headings->[$i][2];

        # Only include parent headings (same or higher level)
        # Level 1 is highest (outermost)
        if ($level <= $headings->[$index][1]) {
            push @path, $heading;
        }
    }

    return join('#', @path);
}

sub _make_anchor {
    my ($class, $heading) = @_;
    my $anchor = lc $heading;
    $anchor =~ s/[^a-z0-9]+/-/g;
    $anchor =~ s/^-|-$//g;
    return $anchor;
}

sub _extract_section {
    my ($class, $lines, $line_start, $line_end) = @_;
    my @section = @{$lines}[$line_start - 1 .. $line_end - 1];
    my $content = join("\n", @section);
    my $char_count = length($content);

    my $preview = $content;
    if (length($preview) > 100) {
        $preview = substr($preview, 0, 100) . '...';
    }

    return ($preview, $char_count);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MCP::Wiki::TOC::Parser - Markdown TOC extraction - pure Perl implementation

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This is a pure-Perl TOC parser. It extracts headings from markdown
by line-by-line parsing, ignoring headings inside code blocks.

For better accuracy with complex markdown, you can later install
L<CommonMark> (XS/C library) which provides AST-based parsing.

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
