package EBook::Ishmael::EBook;
use 5.016;
our $VERSION = '1.07';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(&ebook_id %EBOOK_FORMATS);

use EBook::Ishmael::EBook::CB7;
use EBook::Ishmael::EBook::CBR;
use EBook::Ishmael::EBook::CBZ;
use EBook::Ishmael::EBook::CHM;
use EBook::Ishmael::EBook::Epub;
use EBook::Ishmael::EBook::FictionBook2;
use EBook::Ishmael::EBook::HTML;
use EBook::Ishmael::EBook::KF8;
use EBook::Ishmael::EBook::Mobi;
use EBook::Ishmael::EBook::PalmDoc;
use EBook::Ishmael::EBook::PDF;
use EBook::Ishmael::EBook::Text;
use EBook::Ishmael::EBook::XHTML;
use EBook::Ishmael::EBook::Zip;
use EBook::Ishmael::EBook::zTXT;

our %EBOOK_FORMATS = map { lc $_ => "EBook::Ishmael::EBook::$_" } qw(
	CB7 CBR CBZ CHM Epub FictionBook2 HTML KF8 Mobi PalmDoc PDF Text XHTML Zip
	zTXT
);

sub ebook_id {

	my $file = shift;

	open my $fh, '<', $file
		or die "Failed to open $file for reading: $!\n";
	binmode $fh;

	for my $f (
		# Make sure text is last
		sort {
			return  1 if $a eq 'text';
			return -1 if $b eq 'text';
			return $a cmp $b;
		} keys %EBOOK_FORMATS
	) {

		seek $fh, 0, 0;

		if ($EBOOK_FORMATS{ $f }->heuristic($file, $fh)) {
			close $fh;
			return $f;
		}

	}

	close $fh;
	return undef;

}

sub new {

	my $class = shift;
	my $file  = shift;
	my $type  = shift // ebook_id($file);
	my $enc   = shift;
	my $net   = shift;

	if (not defined $type) {
		die "Could not identify $file format\n";
	}

	my $obj = $EBOOK_FORMATS{ $type }->new($file, $enc, $net);

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

=head1 METHODS

=head2 $e = EBook::Ishmael::EBook->new($file, $type, $enc, $net)

Reads C<$file> and returns some ebook object, the exact class will depend the on
the format of C<$file> or C<$type>. C<$type> is the name of the format you would
like to read C<$file> as. If not specified, C<new()> will try to identify
C<$file>'s format automatically via a series of heuristics. C<$enc> is an
optional argument specify the character encoding to read the ebook format as, if
the ebook format supports user-specified encodings. C<$net> is an optional
boolean argument that determines whether to allow or disallow performing
network operations when reading an ebook.

=head2 $html = $e->html([$out])

Dumps the ebook's HTML-ified contents. Contents will be written to C<$out>, if
provided, otherwise it will be returned as a string.

=head2 $meta = $e->meta()

Returns a hash ref of the ebook object's metadata.

=head2 $raw = $e->raw([$out])

Dumps the ebook's raw, unformatted text contents.

=head2 $bool = $e->has_cover()

Returns bool of whether the ebook has a cover image or not.

=head2 $cover = $e->cover([$out])

Dumps the ebook's cover image data. Returns C<undef> is there is no cover.

=head2 $n = $e->image_num()

Returns the number of images in the ebook.

=head2 $img = $e->image($n)

Returns a scalar ref C<$img> of image data from image C<$n> (starting from
C<0>). Returns C<undef> if the image is not available.

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

L<EBook::Ishmael>,

=cut
