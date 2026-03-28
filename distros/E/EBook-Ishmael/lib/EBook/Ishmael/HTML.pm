package EBook::Ishmael::HTML;
use 5.016;
our $VERSION = '2.04';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(prepare_html text2html);

sub text2html {

    my $text = shift;

    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;

    my @paras = split /(\s*\n){2,}/, $text;

    my $html = join '',
        map { "<p>\n" . $_ . "</p>\n" }
        grep { /\S/ }
        @paras;

    return $html;

}

my %STRIP_NODES = map { $_ => 1 } qw(img style);
my $STRIP_XPATH = join ' | ', map { "//$_" } keys %STRIP_NODES;

sub prepare_html {

    my @nodes = @_;

    my $stripped = 0;

    for my $n (@nodes) {
        my @children = $n->findnodes("//comment() | $STRIP_XPATH");
        for my $c (@children) {
            $c->unbindNode;
        }
        $stripped += scalar @children;
    }

    return $stripped;

}

1;

=head1 NAME

EBook::Ishmael::HTML - Misc. HTML utilities

=head1 SYNOPSIS

  use EBook::Ishmael::HTML qw(text2html prepare_html);

  my $html = text2html(<<"HERE");
  A paragraph.

  Another paragraph!
  HERE

  prepare_html(@nodes);

=head1 DESCRIPTION

B<EBook::Ishmael::HTML> is a module that provides various utilities for HTML
handling. This is a private module, please consult the L<ishmael> manual for
user documentation.

=head1 SUBROUTINES

=head2 $html = text2html($text)

Converts the given string C<$text> to HTML, returning the HTML string.

=head2 $stripped = prepare_html(@nodes)

Prepares the give list of L<XML::LibXML::Node> nodes for dumping by removing
unnecessary elements. Returns the number of nodes removed.

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg Page|https://codeberg.org/1-1sam/ishmael>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025-2026 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<XML::LibXML>, L<XML::LibXML::Node>

=cut
