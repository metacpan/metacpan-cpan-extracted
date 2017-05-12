package IO::File::Cycle;

use 5.006;
use strict;
use warnings;
use base 'IO::File';

=head1 NAME

IO::File::Cycle - Easily split output file while writing

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

This module makes it easy to split a file while writing to it. This, for example, will create a number of files in /tmp called "foo.1.txt", "foo.2.txt", &c., all at most 10,000 bytes in size:

	use IO::File::Cycle;

	my $file = IO::File::Cycle->new('>/tmp/foo.txt');
	for ( 1..100_000 ) {
		$file->cycle if tell($file) + length($_) + 1 > 10_000;
		print $file $_, "\n";
	}
	$file->close;

=head1 SUBROUTINES/METHODS

=head2 start_at()

Defines the starting number, which can be easily overridden in a subclass.

=cut

sub start_at { 1 }

=head2 open()

Sets up some internal variables, then calls IO::File::open().

=cut

sub open {
	my $io = shift;
	my $filename = shift;
	my @mode_and_perms = @_;
	if ( $filename =~ s/^(\+?(<|>|>>))// ) {
		$mode_and_perms[0] = $1;
	}
	(my $base = $filename) =~ s/\.([^.]+)$//;
	*{$io} = \ {
		count          => $io->start_at,
		current        => $filename,
		base           => $base,
		extension      => $1,
		mode_and_perms => \@mode_and_perms,
	};
	$io->SUPER::open($filename, @mode_and_perms);
}

=head2 format_filename()

Formats the filename.

=cut

sub format_filename {
	my $io = shift;
	return join '.', grep $_, $$$io->{base}, shift, $$$io->{extension};
}

=head2 cycle()

Closes the current file, then opens a new file with an incremented number in the filename (before the extension if there is one, and after a "."). After closing the initial file, it renames it to have the index "1" – for example, "filename.1.ext".

=cut

sub cycle {
	my $io = shift;
	$io->close;
	if ( $$$io->{count} == (my $start_at = $io->start_at) ) {
		rename $$$io->{current}, $io->format_filename( $start_at );
	}
	$$$io->{current} = $io->format_filename( ++$$$io->{count} );
	$io->SUPER::open($$$io->{current}, @{$$$io->{mode_and_perms}});
}

=head2 filename()

Returns the current file's name. This can be called from a close() method in a subclass to post-process each file.

=cut

sub filename {
	my $io = shift;
	return $$$io->{current};
}

=head2 close()

This is a sample close() method, which in a subclass could post-process each file.

sub close {
	my $io = shift;
	my $filename = $io->filename;
	$io->SUPER::close;
	system "gzip -f $filename";
}

=cut

=head1 AUTHOR

Nic Wolff, C<< <nic at angel.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-io-file-cycle at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-File-Cycle>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc IO::File::Cycle


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IO-File-Cycle>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-File-Cycle>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IO-File-Cycle>

=item * Search CPAN

L<http://search.cpan.org/dist/IO-File-Cycle/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Nic Wolff.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of IO::File::Cycle
