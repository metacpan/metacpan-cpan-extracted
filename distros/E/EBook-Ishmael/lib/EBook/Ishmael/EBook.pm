package EBook::Ishmael::EBook;
use 5.016;
our $VERSION = '0.03';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(&ebook_id %EBOOK_FORMATS);

use EBook::Ishmael::EBook::Epub;
use EBook::Ishmael::EBook::FictionBook2;
use EBook::Ishmael::EBook::HTML;
use EBook::Ishmael::EBook::Mobi;
use EBook::Ishmael::EBook::PalmDoc;
use EBook::Ishmael::EBook::PDF;
use EBook::Ishmael::EBook::Text;
use EBook::Ishmael::EBook::zTXT;

our %EBOOK_FORMATS = map { lc $_ => "EBook::Ishmael::EBook::$_" } qw(
	Epub FictionBook2 HTML Mobi PalmDoc PDF Text zTXT
);

sub ebook_id {

	my $file = shift;

	for my $f (sort keys %EBOOK_FORMATS) {

		if ($EBOOK_FORMATS{ $f }->heuristic($file)) {
			return $f;
		}

	}

	return undef;

}

sub new {

	my $class = shift;
	my $file  = shift;
	my $type  = shift // ebook_id($file);

	if (not defined $type) {
		die "Could not identify $file format\n";
	}

	my $obj = $EBOOK_FORMATS{ $type }->new($file);

	return $obj;

}

1;

=head1 NAME

EBook::Ishmael::EBook - Interface for processing ebook documents

=head1 SYNOPSIS

  use App::Ishmael::EBook;

  my $ebook = App::Ishmael::EBook->new($file);

=head1 DESCRIPTION

B<EBook::Ishmael::EBook> is a module used by L<ishmael> to read ebook files.
If you are looking for user documentation, you should consult the L<ishmael>
manual (this is developer documentation).

This page will not only detail B<EBook::Ishmael::EBook>'s methods, but some of
the methods of the various specific ebook modules that this module uses, as they
all (mostly) share the same API.

If you would like documentation on writing your own ebook format module, consult
the documentation for L<EBook::Ishmael::EBook::Skeleton>.

=head1 METHODS

=head2 $e = EBook::Ishmael::EBook->new($file, [ $type ])

Reads C<$file> and returns some ebook object, the exact class will depend the on
the format of C<$file> or C<$type>. C<$type> is the name of the format you would
like to read C<$file> as. If not specified, C<new()> will try to identify
C<$file>'s format automatically via a series of heuristics.

=head2 $html = $e->html()

Returns a string of the HTML-ified contents of the ebook object.

=head2 $meta = $e->meta()

Returns a hash ref of the ebook object's metadata.

=head1 SUBROUTINES

=head2 $type = ebook_id($file)

Identifies the ebook format of C<$file> using a series of heuristics. If
C<$file> could not be identified, returns C<undef>.

=head1 EXPORTED VARIABLES

=head2 %EBOOK_FORMATS

Hash of ebook formats and their respective class.

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

=head1 SEE ALSO

L<EBook::Ishmael>, L<EBook::Ishmael::EBook::Skeleton>

=cut
