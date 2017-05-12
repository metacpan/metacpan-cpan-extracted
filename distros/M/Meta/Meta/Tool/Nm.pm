#!/bin/echo This is a perl module and should not be run

package Meta::Tool::Nm;

use strict qw(vars refs subs);
use Meta::Utils::File::Patho qw();
use Meta::Ds::Set qw();

our($VERSION,@ISA);
$VERSION="0.11";
@ISA=qw();

#sub BEGIN();
#sub read($);
#sub TEST($);

#__DATA__

our($tool_path);

sub BEGIN() {
	my($patho)=Meta::Utils::File::Patho->new_path();
	$tool_path=$patho->resolve("nm");
}

sub read($) {
	my($file)=@_;
	my($set)=Meta::Ds::Set->new();
	#do the work
	my($parser)=Meta::Utils::Parse::Text->new();
	my(@args);
	push(@args,$tool_path);
	push(@args,"--dynamic");
	push(@args,$file);
	$parser->init_proc(\@args);
	while(!$parser->get_over()) {
		my($line)=$parser->get_line();
		if($line=~/(.*)\sT\s(.*)$/) {
			my($address,$type,$sym)=($line=~/^(.*)\s(.)\s(.*)$/);
			$set->write($sym);
		}
		$parser->next();
	}
	$parser->fini();
	return($set);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Tool::Nm - run nm and give you the results.

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

	MANIFEST: Nm.pm
	PROJECT: meta
	VERSION: 0.11

=head1 SYNOPSIS

	package foo;
	use Meta::Tool::Nm qw();
	my($object)=Meta::Tool::Nm->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module hides the complexity of running nm from you. Give it
an object file or a library and ask it to read it and it will
return a hash containing the symbols in that file.

=head1 FUNCTIONS

	BEGIN()
	read($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Bootstrap method to find nm.

=item B<read($)>

This function received a file name and runs nm on the file storing
the resulting symbol table in a hash. The function then returns
the hash.

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

	0.00 MV more examples
	0.01 MV perl packaging
	0.02 MV md5 project
	0.03 MV database
	0.04 MV perl module versions in files
	0.05 MV movies and small fixes
	0.06 MV thumbnail user interface
	0.07 MV more thumbnail issues
	0.08 MV website construction
	0.09 MV web site automation
	0.10 MV SEE ALSO section fix
	0.11 MV md5 issues

=head1 SEE ALSO

Meta::Ds::Set(3), Meta::Utils::File::Patho(3), strict(3)

=head1 TODO

-check that the file received is indeed a shared library using File::MMagic.
