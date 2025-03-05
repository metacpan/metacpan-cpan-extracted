package EBook::Ishmael::Decode;
use 5.016;
our $VERSION = '1.00';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(lz77_decode);

sub lz77_decode {

	my $encode = shift;

	my $decode = '';

	while ($encode) {

		my $b = ord substr $encode, 0, 1, '';

		# space + xor byte with 0x80
		if ($b >= 0xc0) {
			$decode .= ' ';
			$decode .= chr($b ^ 0x80);
		# length-distance pair: get next byte, strip 2 leading bits, split byte
		# into 11 bits of distance and 3 bits of length + 3
		} elsif ($b >= 0x80) {
			$b = ($b << 8) + ord substr $encode, 0, 1, '';
			my $d = ($b & 0x3fff) >> 3;
			my $l = ($b & 0x0007) + 3;
			$decode .= substr $decode, -$d, 1 while $l--;
		# literal copy
		} elsif ($b >= 0x09) {
			$decode .= chr $b;
		# copy next 1-8 bytes
		} elsif ($b >= 0x01) {
			$decode .= substr $encode, 0, $b, '';
		# copy null byte
		} else {
			$decode .= "\0";
		}

	}

	return $decode;

}

1;

=head1 NAME

EBook::Ishmael::Decode - Ebook decoding routines

=head1 SYNOPSIS

  use App::Ishmael::Decode qw(lz77_decode);

  my $decode = lz77_decode($data);

=head1 DESCRIPTION

B<EBook::Ishmael::Decode> is a module that provides subroutines for decoding
various kinds of encoded ebook text. For L<ishmael> user documentation, you
should consult its manual (this is developer documentation).

=head1 SUBROUTINES

B<EBook::Ishmael::Decode> does not export any subroutines by default.

=head2 $d = lz77_decode($data)

Decodes PalmDoc lz77-encoded C<$data>, returning the decoded data.

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
