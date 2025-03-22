package EBook::Ishmael::Dir;
use 5.016;
our $VERSION = '1.03';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(dir);

use File::Spec;

sub dir {

	my $dir = shift;

	opendir my ($dh), $dir
		or die "Failed to opendir $dir: $!\n";

	my @files =
		sort
		map { File::Spec->catfile($dir, $_) }
		grep { $_ !~ /^\.\.?$/ }
		readdir $dh;

	closedir $dh;

	return @files;

}

1;

=head1 NAME

EBook::Ishmael::Dir - Get list of files from directory

=head1 SYNOPSIS

  use EBook::Ishmael::Dir;

  my @files = dir('/');

=head1 DESCRIPTION

B<EBook::Ishmael::Dir> is a module that provides the C<dir()> subroutine. This
is developer documentation, for L<ishmael> user documentation you should consult
its manual.

=head1 SUBROUTINES

=over 4

=item @f = dir($dir)

Returns list of files in C<$dir>, sorted. Don't sort the list it returns, for
some reason the list decays into C<$dir>. No idea why.

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
