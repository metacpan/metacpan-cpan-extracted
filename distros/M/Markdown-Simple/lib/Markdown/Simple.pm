package Markdown::Simple;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.14';
use Exporter ();
our @ISA = qw(Exporter);

require XSLoader;
XSLoader::load('Markdown::Simple', $Markdown::Simple::VERSION);

our @EXPORT = qw/markdown_to_html strip_markdown/;

1;

__END__

=head1 NAME

Markdown::Simple - Markdown to HTML

=encoding utf8

=head1 VERSION

Version 0.11

=cut

=head1 SYNOPSIS

  use Markdown::Simple;

  # Functional interface. GFM by default (tables, strikethrough,
  # task lists, autolinks, disallow-raw-html). Output is
  # CommonMark/GFM-conformant HTML.
  my $html = markdown_to_html($markdown);

  # Strict CommonMark.
  my $cm = markdown_to_html($markdown, { gfm => 0 });

  # Opt-out an individual extension.
  my $no_tables = markdown_to_html($markdown, { tables => 0 });

  # Extras off by default.
  my $hb = markdown_to_html($markdown, { hard_breaks => 1 });

  my $plain = strip_markdown($markdown);

  # Object interface — keeps the parser's arena warm between
  # render() calls. Use this when converting many documents in a
  # loop with the same options.
  my $md = Markdown::Simple->new({ gfm => 1 });
  for my $doc (@docs) {
      print $md->render($doc);
  }

=head1 DESCRIPTION

Markdown::Simple is a Perl XS module that converts Markdown text to HTML.
The default rendering mode is GitHub Flavored Markdown (GFM); options
let you switch to strict CommonMark or toggle individual extensions.

Two entry points are provided: the exported procedural function
L</markdown_to_html>, and the object-oriented L</new> / L</render>
pair, which is preferable when you intend to render many documents in
the same process because it reuses the underlying parser arena.

=head1 FUNCTIONS

=head2 markdown_to_html

  markdown_to_html($markdown);
  markdown_to_html($markdown, \%options);

Converts the given Markdown text to HTML. The optional second argument is
a hash reference of feature flags.

The available options are:

=over 12

=item * gfm - preset switch. Defaults to enabled. C<< gfm => 0 >> selects
strict CommonMark (turns tables, strikethrough, task lists, autolink, and
disallow-raw-html off). Individual feature toggles below still override.

=item * tables - GFM tables (default: on in GFM mode)

=item * strikethrough - GFM C<~~strike~~> rendering (default: on in GFM mode)

=item * tasklist - GFM C<- [ ]> task list items (default: on in GFM mode)

=item * autolink - GFM bare-URL autolink scanner (default: on in GFM mode)

=item * disallow_raw_html - escape disallowed raw HTML tags (default: on in GFM mode)

=item * hard_breaks - emit C<< <br /> >> for soft line breaks (default: off)

=item * unsafe - allow C<javascript:>, C<vbscript:>, C<data:> URLs and other
otherwise-stripped dangerous content (default: off)

=item * no_simd - disable SIMD fast paths (default: off; useful for debugging)

=item * strict_utf8 - reject input that is not well-formed UTF-8 with a
fatal C<croak> instead of silently producing best-effort output (default: off)

=back

=head3 Per-syntax disables

Pass any of the following with a false value (C<< feature => 0 >>) to make
the corresponding Markdown construct fall through as literal text instead
of being recognised. All default to enabled.

=over 12

=item * headers - ATX (C<#>) and Setext (C<===>/C<--->) headings

=item * thematic_break - C<--->, C<***>, C<___> horizontal rules

=item * fenced_code - C<```> / C<~~~> fenced code blocks

=item * indented_code - 4-space indented code blocks

=item * blockquote - C<< > >> quoted blocks

=item * ordered_lists - C<1.>, C<2.> ordered lists

=item * unordered_lists - C<->, C<*>, C<+> bullet lists

=item * html - raw HTML blocks and inline HTML

=item * references - link reference definitions (C<[id]: url>)

=item * bold - C<**strong**> / C<__strong__>

=item * italic - C<*em*> / C<_em_>

=item * code - inline C<< `code` >> spans

=item * links - C<[text](url)> and reference links

=item * images - C<< ![alt](src) >>

=back

=head2 strip_markdown

  strip_markdown($markdown);

Removes all Markdown formatting from the given text, returning plain text.
List markers, table pipes, and table separator rows are preserved so that
the output stays scan-readable; bold/italic/strike/code/link/image
delimiters are stripped while their textual content is retained.

=head1 OBJECT INTERFACE

For workloads that render many documents in succession, the object
interface keeps the parser's internal arena and scratch buffers warm
between calls, eliminating the per-render C<malloc>/C<free> traffic
incurred by the procedural entry point.

=head2 new

  my $md = Markdown::Simple->new(\%options);
  my $md = Markdown::Simple->new;            # GFM defaults

Constructs a persistent renderer. C<\%options> is the same hash
reference accepted by L</markdown_to_html>; flags are decoded once at
construction and reused on every C<render> call.

=head2 render

  my $html = $md->render($markdown);

Converts C<$markdown> to HTML using the options bound at construction
time. The arena's head page is reset (not freed) between calls so that
allocations within a typical document complete without touching the
system allocator.

=head2 DESTROY

Releases the C-side arena and scratch buffers. Called automatically by
Perl when the object goes out of scope; you do not need to invoke it
explicitly.

=head1 EXAMPLES

  use Markdown::Simple qw(markdown_to_html);

  my $markdown = "This is **bold** text and this is *italic* text.";
  my $html = markdown_to_html($markdown);
  print $html; # <p>This is <strong>bold</strong> text and this is <em>italic</em> text.</p>

  # Switch to strict CommonMark (no GFM extensions).
  my $cm = markdown_to_html("see http://x\n", { gfm => 0 });

  # Reuse a single parser for many documents.
  my $md = Markdown::Simple->new;
  print $md->render($_) for @docs;

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-markdown-simple at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Markdown-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Markdown::Simple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Markdown-Simple>

=item * Search CPAN

L<https://metacpan.org/release/Markdown-Simple>

=back


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Markdown::Simple
