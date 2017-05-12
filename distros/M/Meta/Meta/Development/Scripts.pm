#!/bin/echo This is a perl module and should not be run

package Meta::Development::Scripts;

use strict qw(vars refs subs);
use DB_File qw();
use Meta::Utils::System qw();
use Meta::Utils::File::File qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw();

#sub set_runline($$);
#sub TEST($);

#__DATA__

sub set_runline($$) {
	my($file,$newline)=@_;
	my($content);
	Meta::Utils::File::File::load($file,\$content);
	$content=~s/^#!.*\n/$newline\n/;
	Meta::Utils::File::File::save($file,$content);
#	my(@arra);
#	tie(@arra,"DB_File",$file,$DB_File::O_RDWR,0666,$DB_File::DB_RECNO) || throw Meta::Error::Simple("cannot tie [".$file."]");
#	$arra[0]=$newline;
#	untie(@arra) || throw Meta::Error::Simple("cannot untie [".$file."]");
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Development::Scripts - help you with doing script related tasks.

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

	MANIFEST: Scripts.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Development::Scripts qw();
	my($object)=Meta::Development::Scripts->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module is here to help you with performing script related tasks.

=head1 FUNCTIONS

	set_runline($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<set_runline($$)>

This method will set the interpreter runline for a script given to it.

=item B<TEST($)>

This is a testing suite for the Meta::Development::Scripts module.
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

	0.00 MV web site development
	0.01 MV md5 issues

=head1 SEE ALSO

DB_File(3), Error(3), Meta::Utils::File::File(3), Meta::Utils::System(3), strict(3)

=head1 TODO

Nothing.
