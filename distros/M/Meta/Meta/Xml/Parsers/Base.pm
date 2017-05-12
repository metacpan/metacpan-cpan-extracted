#!/bin/echo This is a perl module and should not be run

package Meta::Xml::Parsers::Base;

use strict qw(vars refs subs);
use XML::Parser::Expat qw();
use Meta::Utils::Output qw();
use Meta::Baseline::Aegis qw();
use Meta::Utils::File::File qw();
use Meta::Utils::Utils qw();

our($VERSION,@ISA);
$VERSION="0.12";
@ISA=qw(XML::Parser::Expat);

#sub new($);
#sub in_context($$$);
#sub in_ccontext($$);
#sub in_abs_context($$$);
#sub in_abs_ccontext($$);
#sub handle_externent($$$$);
#sub parsefile_deve($$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)=XML::Parser::Expat->new();
	if(!$self) {
		throw Meta::Error::Simple("didn't get a parser");
	}
	$self->setHandlers(
		'ExternEnt'=>\&handle_externent,
	);
	bless($self,$class);
	return($self);
}

sub in_context($$$) {
	my($self,$stri,$elem)=@_;
	my($context)=join(".",$self->context(),$elem);
#	Meta::Utils::Output::print("checking [".$stri."] [".$context."]\n");
	my($res)=Meta::Utils::Utils::is_suffix($context,$stri);
#	Meta::Utils::Output::print("res is [".$res."]\n");
	return($res);
}

sub in_ccontext($$) {
	my($self,$stri)=@_;
	my($context)=join(".",$self->context());
#	Meta::Utils::Output::print("checking [".$stri."] [".$context."]\n");
	my($res)=Meta::Utils::Utils::is_suffix($context,$stri);
#	Meta::Utils::Output::print("res is [".$res."]\n");
	return($res);
}

sub in_abs_context($$$) {
	my($self,$stri,$elem)=@_;
	my($context)=join(".",$self->context(),$elem);
	return($stri eq $context);
}

sub in_abs_ccontext($$) {
	my($self,$stri)=@_;
	my($context)=join(".",$self->context());
	return($stri eq $context);
}

sub handle_externent($$$$) {
	my($self,$base,$sysi,$pubi)=@_;
	my($find)=Meta::Baseline::Aegis::which($sysi);
	my($data);
	Meta::Utils::File::File::load($find,\$data);
	#Meta::Utils::Output::print("in handle_externent\n");
	#Meta::Utils::Output::print("base is [".$base."]\n");
	#Meta::Utils::Output::print("sysi is [".$sysi."]\n");
	#Meta::Utils::Output::print("pubi is [".$pubi."]\n");
	return($data);
}

sub parsefile_deve($$) {
	my($self,$file)=@_;
	$self->parsefile(Meta::Baseline::Aegis::which($file));
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Xml::Parsers::Base - object to derive XML parsers from.

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

	MANIFEST: Base.pm
	PROJECT: meta
	VERSION: 0.12

=head1 SYNOPSIS

	package foo;
	use Meta::Xml::Parsers::Base qw();
	my($def_parser)=Meta::Xml::Parsers::Base->new();
	$def_parser->parsefile($file);
	my($def)=$def_parser->get_result();

=head1 DESCRIPTION

Derive all your XML/Expat parsers from this one.

=head1 FUNCTIONS

	new($)
	in_context($$$)
	in_ccontext($$)
	in_abs_context($$$)
	in_abs_ccontext($$)
	handle_externent($$$$)
	parsefile_deve($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This gives you a new object for a parser.

=item B<in_context($$$)>

This method will return true if you are in a postfix context.
This is a service method to derived classes.

=item B<in_ccontext($$)>

Same as the above in_context except for char handling.

=item B<in_abs_context($$$)>

This method will return true if you are in a specific context.
This is a service method to derived classes.

=item B<in_abs_ccontext($$)>

Same as the above in_abs_context except for char handling.

=item B<handle_externent($$$$)>

This method will handle resolving external references.

=item B<parsefile_deve($$)>

This method will do the same as the parents parsefile except it will
search for the file in the development context.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

XML::Parser::Expat(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV perl packaging
	0.01 MV db inheritance
	0.02 MV md5 project
	0.03 MV database
	0.04 MV perl module versions in files
	0.05 MV movies and small fixes
	0.06 MV movie stuff
	0.07 MV thumbnail user interface
	0.08 MV more thumbnail issues
	0.09 MV website construction
	0.10 MV web site automation
	0.11 MV SEE ALSO section fix
	0.12 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Utils::File::File(3), Meta::Utils::Output(3), Meta::Utils::Utils(3), XML::Parser::Expat(3), strict(3)

=head1 TODO

Nothing.
