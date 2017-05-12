#!/bin/echo This is a perl module and should not be run

package Meta::Template;

use strict qw(vars refs subs);
use Error qw(:try);
use Template qw();

our($VERSION,@ISA);
$VERSION="0.00";
@ISA=qw(Template);

#sub process($$$$);
#sub TEST($);

#__DATA__

sub process($$$$) {
	my($self,$one,$two,$three)=@_;
	my($res)=$self->SUPER::process($one,$two,$three);
	if(!$res) {
		throw Meta::Error::Simple("error in template processing [".$self->error()."][".$one."][".$two."][".$three."]");
	}
}

sub TEST($) {
	my($context)=@_;
	my($string)=@_;
	my($vars)={
		"mark","veltzer",
	};
	my($template)=Meta::Template->new();
	my($result);
	$template->process(\"mark [% mark %]",$vars,\$result);
	Meta::Utils::Output::print("results is [".$result."]\n");
	return(1);
}

1;

__END__

=head1 NAME

Meta::Template - enhance/extends Template.pm from CPAN.

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

	MANIFEST: Template.pm
	PROJECT: meta
	VERSION: 0.00

=head1 SYNOPSIS

	package foo;
	use Meta::Template qw();
	my($object)=Meta::Template->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This module provides enhancements I want for Template.pm from CPAN.
Currently this only includes some exception handling.

=head1 FUNCTIONS

	process($$$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<process($$$$)>

This method overrides the TT2 process method and throws an exception if
something goes wrong instead of returning an error code.

=item B<TEST($)>

This is a testing suite for the Meta::Template module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

=back

=head1 SUPER CLASSES

Template(3)

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

Error(3), Template(3), strict(3)

=head1 TODO

Nothing.
