package EBook::Ishmael::Unzip;
use 5.016;
our $VERSION = '1.06';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(safe_tmp_unzip unzip);

use Cwd;
use File::Spec;
use File::Temp qw(tempdir);

use Archive::Zip qw(:ERROR_CODES :CONSTANTS);

sub safe_tmp_unzip {

	# Archive::Zip does not support unzipping to symlinked directory. This is a
	# problem on platforms like Darwin, as /tmp is symlinked.
	if (not -l File::Spec->tmpdir) {
		return tempdir(CLEANUP => 1);
	# Try working directory...
	} elsif (! -l cwd and -w cwd) {
		return tempdir(DIR => cwd, CLEANUP => 1);
	# Try HOME...
	} elsif (
		exists $ENV{HOME} and
		-d $ENV{HOME}     and
		! -l $ENV{HOME}   and
		-w $ENV{HOME}
	) {
		return tempdir(DIR => $ENV{HOME}, CLEANUP => 1);
	# Give up and die :-(
	} else {
		die "Could not find a suitable unzip directory\n";
	}

}

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

  use EBook::Ishmael::Unzip qw(unzip);

  unzip($zip, $out);

=head1 DESCRIPTION

B<EBook::Ishmael::Unzip> is a module that provides the C<unzip()> subroutine,
which unzips a given Zip file to a specified directory. This is developer
documentation, for L<ishmael> user documentation you should consult its manual.

=head1 SUBROUTINES

=over 4

=item $tmpdir = safe_tmp_unzip()

Creates and returns a suitable temporary unzip directory. This function exists
because Archive::Zip cannot unzip to some kinds of directories, like symlinked
ones, which can be problematic on platforms such as Darwin where their F</tmp>
directory is symlinked by default.

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
