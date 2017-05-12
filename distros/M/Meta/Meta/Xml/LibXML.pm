#!/bin/echo This is a perl module and should not be run

package Meta::Xml::LibXML;

use strict qw(vars refs subs);
use XML::LibXML qw();
use Meta::Baseline::Aegis qw();
use Meta::Utils::File::File qw();
use Meta::Utils::Utils qw();
use File::Basename qw();
use LWP::Simple qw();

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw(XML::LibXML);

#sub resolver($$);
#sub new_aegis($);
#sub parse_file($$);
#sub check_file($$);
#sub TEST($);

#__DATA__

our($file_path);

sub resolver($$) {
	my($full,$id)=@_;
	#Meta::Utils::Output::print("full is [".$full."]\n");
	#Meta::Utils::Output::print("id is [".$id."]\n");
	my($content);
	if($full=~/^http:\/\//) {
		$content=LWP::Simple::get($full);
	} else {
		if($full=~/^temp\/dtdx\/deve\/xml\//) {
			my($correct)="dtdx".Meta::Utils::Utils::minus($full,"temp/dtdx/deve/xml");
			$correct=Meta::Baseline::Aegis::which($correct);
			#Meta::Utils::Output::print("correct is [".$correct."]\n");
			Meta::Utils::File::File::load($correct,\$content);
		} else {
			my($correct)="dtdx".Meta::Utils::Utils::minus($full,$file_path);
			$correct=Meta::Baseline::Aegis::which($correct);
			#Meta::Utils::Output::print("correct is [".$correct."]\n");
			Meta::Utils::File::File::load($correct,\$content);
		}
	}
	#Meta::Utils::Output::print("content is [".$content."]\n");
	#if return here is "" then LibXML will segfault. This is pretty bad.
	return($content);
}

sub new_aegis($) {
	my($class)=@_;
	my($self)=XML::LibXML::new($class,ext_ent_handler=>\&resolver);
	#my($self)=XML::LibXML::new($class);
#	CORE::bless($self,$class);
	return($self);
}

sub parse_file($$) {
	my($self,$file)=@_;
	$file_path=File::Basename::dirname($file);
	return($self->SUPER::parse_file($file));
}

sub check_file($$) {
	my($self,$file)=@_;
	$file_path=File::Basename::dirname($file);
	my($doc);
	#Meta::Utils::Output::print("in here\n");
	eval {
		$doc=$self->SUPER::parse_file($file);
	};
	#Meta::Utils::Output::print("out here\n");
	my($scod);
	if($@) {
		Meta::Utils::Output::print($@);
		$scod=0;
	} else {
		$scod=1;
	}
	return($scod);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Xml::LibXML - extend/enhance the XML::LibXML module.

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

	MANIFEST: LibXML.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Xml::LibXML qw();
	my($object)=Meta::Xml::LibXML->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class extends the XML::LibXML class to do aegis path resolution.
Just call the new_aegis method and get a parser which does that for you.

=head1 FUNCTIONS

	resolver($$)
	new_aegis($)
	parse_file($$)
	check_file($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<resolver($$)>

A static method which does the actual resolution.

=item B<new_aegis($)>

This is a constructor for the Meta::Xml::LibXML object.

=item B<parse_file($$)>

Overriden method for the parent because we need to store the path of the file
currently parsed because we need to get ridd of it. Read the todo item below
to understand why. This interface keeps the old XML::LibXML interface so that
you won't know anything about it.

=item B<TEST($)>

This is a testing suite for the Meta::Xml::LibXML module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

=back

=head1 SUPER CLASSES

XML::LibXML(3)

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

File::Basename(3), LWP::Simple(3), Meta::Baseline::Aegis(3), Meta::Utils::File::File(3), Meta::Utils::Utils(3), XML::LibXML(3), strict(3)

=head1 TODO

-talk to the LibXML guys (perl or c level) and ask why the extenal handler doesnt get what's in the document but rather a catenated path. This makes my life rather difficult.

-mail the LibXML guys about why I can inherit the external handler (call the parent implementation or something).
