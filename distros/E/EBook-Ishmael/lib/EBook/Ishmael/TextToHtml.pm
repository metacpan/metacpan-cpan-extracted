package EBook::Ishmael::TextToHtml;
use 5.016;
our $VERSION = '1.01';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(text2html);

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

1;

=head1 NAME

EBook::Ishmael::TextToHtml - Convert plain text to HTML

=head1 SYNOPSIS

  use EBook::Ishmael::TextToHtml;

  my $html = text2html($text);

=head1 DESCRIPTION

B<EBook::Ishmael::TextToHtml> is a module that provides the subroutine
C<text2html()> to perform basic text-to-HTML conversion. If you are looking for
L<ishmael> user documentation, you should consult its manual (this is developer
documentation).

=head1 SUBROUTINES

=head2 $html = text2html($text)

Converts the given string C<$text> to HTML, returning the HTML string.

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg Page|https://codeberg.org/1-1sam/ishmael>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=cut
