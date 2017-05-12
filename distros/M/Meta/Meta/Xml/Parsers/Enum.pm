#!/bin/echo This is a perl module and should not be run

package Meta::Xml::Parsers::Enum;

use strict qw(vars refs subs);
use Meta::Info::Enum qw();
use Meta::Xml::Parsers::Collector qw();

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw(Meta::Xml::Parsers::Collector);

#sub new($);
#sub get_result($);
#sub handle_start($$);
#sub handle_end($$);
#sub handle_endchar($$$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)=Meta::Xml::Parsers::Collector::new($class);
	$self->setHandlers(
		'Start'=>\&handle_start,
		'End'=>\&handle_end,
	);
	#bless($self,$class);
	$self->{TEMP_ENUM}=defined;
	return($self);
}

sub get_result($) {
	my($self)=@_;
	return($self->{TEMP_ENUM});
}

sub handle_start($$) {
	my($self,$elem)=@_;
	$self->SUPER::handle_start($elem);
	#Meta::Utils::Output::print("in handle_start with elem [".$elem."]\n");
	if($elem eq "enum") {
		$self->{TEMP_ENUM}=Meta::Info::Enum->new();
	}
}

sub handle_end($$) {
	my($self,$elem)=@_;
	$self->SUPER::handle_end($elem);
	if($elem eq "member") {
		my($temp_name)=$self->{TEMP_NAME};
		my($temp_description)=$self->{TEMP_DESCRIPTION};
		$self->{TEMP_ENUM}->insert($temp_name,$temp_description);
	}
}

sub handle_endchar($$$) {
	my($self,$elem,$name)=@_;
	#Meta::Utils::Output::print("in here with elem [".$elem."],[".join(',',$self->context(),$name)."]\n");
	$self->SUPER::handle_endchar($elem);
	if($self->in_context("enum.name",$name)) {
		$self->{TEMP_ENUM}->set_name($elem);
	}
	if($self->in_context("enum.description",$name)) {
		$self->{TEMP_ENUM}->set_description($elem);
	}
	if($self->in_context("enum.members.member.name",$name)) {
		$self->{TEMP_NAME}=$elem;
	}
	if($self->in_context("enum.members.member.description",$name)) {
		$self->{TEMP_DESCRIPTION}=$elem;
	}
	if($self->in_context("enum.default",$name)) {
		$self->{TEMP_ENUM}->set_default($elem);
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Xml::Parsers::Enum - parse XML/Enum into objects.

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

	MANIFEST: Enum.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Xml::Parsers::Enum qw();
	my($object)=Meta::Xml::Parsers::Enum->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This object is an XML parser which can parse XML/Enum files and produce the
corresponding Meta::Info::Enum object.

=head1 FUNCTIONS

	new($)
	get_result($)
	handle_start($$)
	handle_end($$)
	handle_endchar($$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This is a constructor for the Meta::Xml::Parsers::Enum object.

=item B<get_result($)>

This method will retrieve the result of the parsing process.

=item B<handle_start($$)>

This will handle start tags.

=item B<handle_end($$)>

This will handle end tags.
This currently does nothing.

=item B<handle_endchar($$$)>

This will handle actual text.

=item B<TEST($)>

This is a testing suite for the Meta::Xml::Parsers::Enum module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

=back

=head1 SUPER CLASSES

Meta::Xml::Parsers::Collector(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV teachers project
	0.01 MV md5 issues

=head1 SEE ALSO

Meta::Info::Enum(3), Meta::Xml::Parsers::Collector(3), strict(3)

=head1 TODO

-fix the constructor here or else explain in the code why is it so weird. Or maybe that this is the best way to do the constructor and we should change all the others to match ?!?
