#!/bin/echo This is a perl module and should not be run

package Meta::Tool::Less;

use strict qw(vars refs subs);
use Meta::Utils::Utils qw();
use Meta::Utils::File::File qw();
use Meta::Utils::System qw();
use Meta::Utils::File::Remove qw();
use Meta::Utils::File::Patho qw();

our($VERSION,@ISA);
$VERSION="0.05";
@ISA=qw();

#sub BEGIN();
#sub show_file($);
#sub show_data($);
#sub TEST($);

#__DATA__

our($tool_path);

sub BEGIN() {
	my($patho)=Meta::Utils::File::Patho->new_path();
	$tool_path=$patho->resolve("less");
}

sub show_file($) {
	my($file)=@_;
	Meta::Utils::System::system($tool_path,["-csi",$file]);
}

sub show_data($) {
	my($data)=@_;
	my($name)=Meta::Utils::Utils::get_temp_file();
	Meta::Utils::File::File::save($name,$data);
	&show_file($name);
	Meta::Utils::File::Remove::rm($name);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Tool::Less - run the less pager for you.

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

	MANIFEST: Less.pm
	PROJECT: meta
	VERSION: 0.05

=head1 SYNOPSIS

	package foo;
	use Meta::Tool::Less qw();
	my($object)=Meta::Tool::Less->new();
	my($result)=$object->method();

=head1 DESCRIPTION

When you want to show something using the less pager don't do it
yourself - give this module the job.

=head1 FUNCTIONS

	BEGIN()
	show_file($)
	show_data($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Bootstrap method to find the path to your less executable.

=item B<show_file($)>

This method will show a file using the less pager.

=item B<show_data($)>

Pass this method some data and it will show it using the less pager.

=item B<TEST($)>

Test suite for this module.

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

	0.00 MV import tests
	0.01 MV more thumbnail issues
	0.02 MV website construction
	0.03 MV web site automation
	0.04 MV SEE ALSO section fix
	0.05 MV md5 issues

=head1 SEE ALSO

Meta::Utils::File::File(3), Meta::Utils::File::Patho(3), Meta::Utils::File::Remove(3), Meta::Utils::System(3), Meta::Utils::Utils(3), strict(3)

=head1 TODO

-is there a way (using some CPAN module?) to feed the string to the less pager without writing it first into a file ?
