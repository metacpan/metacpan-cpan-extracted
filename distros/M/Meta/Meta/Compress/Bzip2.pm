#!/bin/echo This is a perl module and should not be run

package Meta::Compress::Bzip2;

use strict qw(vars refs subs);
use Meta::IO::File qw();

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw();

#sub FileToFileCompress($$);
#sub TEST($);

#__DATA__

sub FileToFileCompress($$) {
	my($source,$target)=@_;
	my($io)=Meta::IO::File->new_reader($source);
	while(!$io->eof()) {
		my($line)=$io->cgetline();
	}
	$io->close();
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Compress::Bzip2 - extend Compress::Bzip2 to give higher level services.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: Bzip2.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Compress::Bzip2 qw();
	my($object)=Meta::Compress::Bzip2->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class is here to extend Compress::Bzip2 which has two major issues:
1. It's documentation is lacking (it only documents two methods: compress
and decompress) and refers the reader to the bzip2 libraries API which I
could only get out of the appropriate h file (/usr/include/bzlib.h).
2. It doesnt have file to file compressing which is the most common use
of such a library.

=head1 FUNCTIONS

	FileToFileCompress($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<FileToFileCompress($$)>

This method receives a source file and a destination file and compresses
the source file into the destination file. The source file is NOT removed
at the end of the compression process. The method just reads the input file
a small chunk at a time and feeds the Compress::Bzip2 compressor which
slowly writes the output.

=item B<TEST($)>

This is a testing suite for the Meta::Compress::Bzip2 module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

=back

=head1 SUPER CLASSES

None.

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV move tests to modules
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::IO::File(3), strict(3)

=head1 TODO

Nothing.
