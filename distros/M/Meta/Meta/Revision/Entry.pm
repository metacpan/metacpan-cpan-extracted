#!/bin/echo This is a perl module and should not be run

package Meta::Revision::Entry;

use strict qw(vars refs subs);
use Meta::Math::Pad qw();
use Meta::Class::MethodMaker qw();

our($VERSION,@ISA);
$VERSION="0.20";
@ISA=qw();

#sub BEGIN();
#sub print($$);
#sub printd($$);
#sub string($);
#sub perl_pod_line($$);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->new("new");
	Meta::Class::MethodMaker->get_set(
		-java=>"_number",
		-java=>"_date",
		-java=>"_initials",
		-java=>"_remark",
		-java=>"_description",
		-java=>"_action",
		-java=>"_change",
		-java=>"_delta",
	);
}

sub print($$) {
	my($self,$file)=@_;
	print $file "number is [".$self->get_number()."]\n";
	print $file "date is [".$self->get_date()."]\n";
	print $file "initials is [".$self->get_initials()."]\n";
	print $file "remark is [".$self->get_remark()."]\n";
	print $file "description is [".$self->get_description()."]\n";
	print $file "action is [".$self->get_action()."]\n";
	print $file "change is [".$self->get_change()."]\n";
	print $file "delta is [".$self->get_delta()."]\n";
}

sub printd($$) {
	my($self,$writ)=@_;
	$writ->startTag("revision");
	$writ->startTag("revnumber");
	$writ->characters($self->get_number());
	$writ->endTag("revnumber");
	$writ->startTag("date");
	$writ->characters($self->get_date());
	$writ->endTag("date");
	$writ->startTag("authorinitials");
	$writ->characters($self->get_initials());
	$writ->endTag("authorinitials");
	$writ->startTag("revremark");
	$writ->characters($self->get_remark());
	$writ->endTag("revremark");
	#$writ->startTag("revdescription");
	#$writ->characters($self->get_description());
	#$writ->endTag("revdescription");
	$writ->endTag("revision");
}

sub string($) {
	my($self)=@_;
	my($retu)=join("\t",$self->get_number(),$self->get_date(),$self->get_initials(),$self->get_remark())."\n";
	return($retu);
}

sub perl_pod_line($$) {
	my($self,$numb)=@_;
	my($retu)="\t0.".Meta::Math::Pad::pad($numb,2)." ".$self->get_initials()." ".$self->get_remark()."\n";
	return($retu);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Revision::Entry - a single revision of a source file entry.

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

	MANIFEST: Entry.pm
	PROJECT: meta
	VERSION: 0.20

=head1 SYNOPSIS

	package foo;
	use Meta::Revision::Entry qw();
	my($object)=Meta::Revision::Entry->new();
	my($result)=$object->printd($xml);

=head1 DESCRIPTION

This object represents a single revision entry in a list of revisions
made to a source file. It has a couple of basic elements in it: the
revisors initials, the revision number, the date of the revision and
remarks that accompanied the revision.

You can print this revision data in various formats (Docbook) and other
uses. The idea is that if you have a tool (like a Source Control system)
which has revision information you would write import code which will
create these types of object and then ask them to output themselves
in whatever.

=head1 FUNCTIONS

	BEGIN()
	print($$)
	printd($$)
	string($)
	perl_pod_line($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

This block sets up the Entry object which has the following attributes:
number: the number of the current revision.
date: date at which the revision was made.
initials: initials of the author who made the revision.
remark: short remark which accompanied the revision.
action: which action did the revision perform (new, update, delete).
change: with which change (piece of work or a formal definition of
a source control system) was the revision associated ?
delta: what was the number of the change with which the revision
was associated with ?

=item B<print($$)>

This method prints the revision object to a regular file.

=item B<printd($$)>

This method will print the current object in DocBook XML format using a
writer object received. Take heed that the DocBook DTD only allows
revremark OR revdescription and not both.

=item B<string($)>

This method will return a string representing the entire information for this
entry.

=item B<perl_pod_line($$)>

This method will return the revision entry in a manner suitable for insertion in
a perl POD section.

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

	0.00 MV more perl code quality
	0.01 MV revision change
	0.02 MV better general cook schemes
	0.03 MV revision in files
	0.04 MV languages.pl test online
	0.05 MV history change
	0.06 MV perl packaging
	0.07 MV PDMT
	0.08 MV md5 project
	0.09 MV database
	0.10 MV perl module versions in files
	0.11 MV movies and small fixes
	0.12 MV md5 progress
	0.13 MV thumbnail project basics
	0.14 MV thumbnail user interface
	0.15 MV more thumbnail issues
	0.16 MV website construction
	0.17 MV web site development
	0.18 MV web site automation
	0.19 MV SEE ALSO section fix
	0.20 MV md5 issues

=head1 SEE ALSO

Meta::Class::MethodMaker(3), Meta::Math::Pad(3), strict(3)

=head1 TODO

Nothing.
