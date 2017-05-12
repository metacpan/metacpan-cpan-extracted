#!/bin/echo This is a perl module and should not be run

package Meta::IO::File;

use strict qw(vars refs subs);
use IO::File qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.00";
@ISA=qw(IO::File);

#sub new($$$);
#sub new_reader($$);
#sub new_writer($$);
#sub cgetline($);
#sub TEST($);

#__DATA__

sub new($$$) {
	my($class,$file,$mode)=@_;
	my($self)=IO::File::new($class,$file,$mode);
	if(!$self) {
		throw Meta::Error::Simple("unable to open IO::File with file [".$file."] and mode [".$mode."]");
	}
	#bless($self,$class);
	return($self);
}

sub new_reader($$) {
	my($class,$file)=@_;
	return(Meta::IO::File::new($class,$file,"r"));
}

sub new_writer($$) {
	my($class,$file)=@_;
	return(Meta::IO::File::new($class,$file,"w"));
}

sub cgetline($) {
	my($self)=@_;
	my($line)=$self->getline();
	CORE::chop($line);
	return($line);
}

sub TEST($) {
	my($context)=@_;
	my($object)=__PACKAGE__->new_reader("/etc/passwd");
	while(!$object->eof()) {
		my($line)=$object->getline();
		Meta::Utils::Output::print($line);
	}
	$object->close();
	return(1);
}

1;

__END__

=head1 NAME

Meta::IO::File - extend IO::File.

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

	MANIFEST: File.pm
	PROJECT: meta
	VERSION: 0.00

=head1 SYNOPSIS

	package foo;
	use Meta::IO::File qw();
	my($object)=Meta::IO::File->new_reader("/etc/passwd");
	while(!$object->eof()) {
		my($line)=$io->getline();
		Meta::Utils::Output::print($line);
	}
	$object->close();

=head1 DESCRIPTION

This class extends IO::File. I'm not actually adding a lot of IO stuff but rather
making the code which uses IO::File cleaner by having my Meta::IO::File throw
exception instead of returning error codes so that it will fit nicer in OO systems.

=head1 FUNCTIONS

	new($$$)
	new_reader($$);
	new_writer($$);
	cgetline($);
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($$$)>

This is a constructor for the Meta::IO::File object.
It overrides the IO::File file,mode constructor, calls it, and throws
an exception if something bad happens.

=item B<new_reader($$)>

Convenience method for creating a file handle for reading a file.

=item B<new_writer($$)>

Converniece method for creating a file handle for writing to a file.

=item B<cgetline($)>

Same as getline except the output is chopped.

=item B<TEST($)>

This is a testing suite for the Meta::IO::File module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.
Currently this just opens /etc/passwd and closes it which should be enough.

=back

=head1 SUPER CLASSES

IO::File(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV md5 issues

=head1 SEE ALSO

Error(3), IO::File(3), strict(3)

=head1 TODO

-make the TEST procedure as the test framework for a readonly existing file and not count on /etc/passwd being there.
