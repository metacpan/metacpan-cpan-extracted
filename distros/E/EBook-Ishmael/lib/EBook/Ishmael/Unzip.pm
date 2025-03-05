package EBook::Ishmael::Unzip;
use 5.016;
our $VERSION = '1.00';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(unzip);

use Archive::Zip qw(:ERROR_CODES :CONSTANTS);

sub unzip {

	my $zip = shift;
	my $out = shift;

	my $obj = Archive::Zip->new;

	unless ($obj->read($zip) == AZ_OK) {
		die "Could not read $zip as a zip archive\n";
	}

	for my $m ($obj->members) {
		$m->unixFileAttributes($m->isDirectory ? 0755 : 0644);
	}

	unless ($obj->extractTree('', $out) == AZ_OK) {
		die "Could not unzip $zip to $out\n";
	}

	return 1;

}

1;

=head1 NAME

EBook::Ishmael::Unzip - Unzip Zip archives

=head1 SYNOPSIS

  use EBook::Ishmael::Unzip;

  unzip($zip, $out);

=head1 DESCRIPTION

B<EBook::Ishmael::Unzip> is a module that provides the C<unzip()> subroutine,
which unzips a given Zip file to a specified directory. This is developer
documentation, for L<ishmael> user documentation you should consult its manual.

=head1 SUBROUTINES

=over 4

=item unzip($zip, $out)

Unzips C<$zip> to the C<$out> directory. Returns C<1> if successful.

=back

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
