package Markdown::Simple;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.11';
use parent qw(Exporter);

require XSLoader;
XSLoader::load('Markdown::Simple', $Markdown::Simple::VERSION);

our @EXPORT = qw/markdown_to_html strip_markdown/;

1;

__END__

=head1 NAME

Markdown::Simple - Markdown to HTML

=head1 VERSION

Version 0.11

=cut

=head1 SYNOPSIS

This module was 100% generated using co-pilot with the prompt:

"create a simple markdown to html perl XS module that allows you to optionally enable each element of markdown. For example I can disable the parsing of image"

then:

"great now extend with table and a few of the other options like task list"

A few more prompts were needed to add ordered and unordered lists.

  use Markdown::Simple;

  markdown_to_html($markdown);

  markdown_to_html($markdown, {
    images => 0, # disable images
    code => 0, # disable code blocks
    links => 0, # disable links
  });

  my $plain = strip_markdown($markdown);

=head1 DESCRIPTION

Markdown::Simple is a simple Perl XS module that converts Markdown text to HTML. It allows you to enable or disable specific Markdown features such as images, code blocks, links, and more.

=head1 FUNCTIONS

=head2 markdown_to_html

  markdown_to_html($markdown, \%options);

Converts the given Markdown text to HTML. The second argument is an optional hash reference that allows you to enable or disable specific Markdown features.

The available options are:

=head2 strip_markdown

  strip_markdown($markdown);

Removes all Markdown formatting from the given text, returning plain text.

=over 12

=item * preprocess - Enable or disable preprocessing (default: enabled). Replaces \r\n with \n

=item * headers - Enable or disable header parsing (default: enabled)

=item * images - Enable or disable image parsing (default: enabled)

=item * code - Enable or disable code block parsing (default: enabled)

=item * links - Enable or disable link parsing (default: enabled)

=item * fenced_code - Enable or disable fenced code block parsing (default: enabled)

=item * bold - Enable or disable bold text parsing (default: enabled)

=item * italic - Enable or disable italic text parsing (default: enabled)

=item * strikethrough - Enable or disable strikethrough text parsing (default: enabled)

=item * task_lists - Enable or disable task list parsing (default: enabled)

=item * unordered_lists - Enable or disable unordered list parsing (default: enabled)

=item * ordered_lists - Enable or disable ordered list parsing (default: enabled)

=item * tables - Enable or disable table parsing (default: enabled)

=back

=head1 EXAMPLES

  use Markdown::Simple qw(markdown_to_html);

  my $markdown = "This is **bold** text and this is *italic* text.";
  my $html = markdown_to_html($markdown);
  print $html; # Outputs: This is <strong>bold</strong> text and this is <em>italic</em> text.

  my $markdown_with_options = "![alt text](image.jpg)";
  my $html_with_options = markdown_to_html($markdown_with_options, { images => 0 });
  print $html_with_options; # Outputs: ![alt text](image.jpg)

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


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Markdown::Simple
