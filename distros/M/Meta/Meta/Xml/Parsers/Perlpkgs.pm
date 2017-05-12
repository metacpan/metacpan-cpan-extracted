#!/bin/echo This is a perl module and should not be run

package Meta::Xml::Parsers::Perlpkgs;

use strict qw(vars refs subs);
use Meta::Lang::Perl::Perlpkgs qw();
use Meta::Lang::Perl::Perlpkg qw();
use Meta::Xml::Parsers::Author qw();
use Meta::Utils::Output qw();
use Meta::Development::PackModule qw();
use Meta::Info::Credit qw();

our($VERSION,@ISA);
$VERSION="0.18";
@ISA=qw(Meta::Xml::Parsers::Author);

#sub new($);
#sub get_result($);
#sub handle_start($$);
#sub handle_end($$);
#sub handle_endchar($$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
#	Meta::Utils::Output::print("before creating author\n");
	my($self)=Meta::Xml::Parsers::Author->new();
#	Meta::Utils::Output::print("before setting handlers\n");
	$self->setHandlers(
		'Start'=>\&handle_start,
		'End'=>\&handle_end,
	);
	$self->{TEMP_PERLPKG}=defined;
	$self->{TEMP_MODULE}=defined;
	$self->{TEMP_SCRIPT}=defined;
	$self->{TEMP_TEST}=defined;
	$self->{TEMP_FILE}=defined;
	$self->{TEMP_CREDIT}=defined;
	bless($self,$class);
	return($self);
}

sub get_result($) {
	my($self)=@_;
	return($self->{RESULT});
}

sub handle_start($$) {
	my($self,$elem)=@_;
	$self->SUPER::handle_start($elem);
	if($self->in_context("perlpkgs",$elem)) {
		$self->{TEMP_PERLPKGS}=Meta::Lang::Perl::Perlpkgs->new();
	}
	if($self->in_context("perlpkgs.perlpkg",$elem)) {
		$self->{TEMP_PERLPKG}=Meta::Lang::Perl::Perlpkg->new();
	}
	if($self->in_context("perlpkgs.perlpkg.modules.module",$elem)) {
		$self->{TEMP_MODULE}=Meta::Development::PackModule->new();
	}
	if($self->in_context("perlpkgs.perlpkg.scripts.script",$elem)) {
		$self->{TEMP_SCRIPT}=Meta::Development::PackModule->new();
	}
	if($self->in_context("perlpkgs.perlpkg.tests.test",$elem)) {
		$self->{TEMP_TEST}=Meta::Development::PackModule->new();
	}
	if($self->in_context("perlpkgs.perlpkg.files.file",$elem)) {
		$self->{TEMP_FILE}=Meta::Development::PackModule->new();
	}
	if($self->in_context("perlpkgs.perlpkg.credits.credit",$elem)) {
		$self->{TEMP_CREDIT}=Meta::Info::Credit->new();
	}
}

sub handle_end($$) {
	my($self,$elem)=@_;
	$self->SUPER::handle_end($elem);
	if($self->in_context("perlpkgs",$elem)) {
		$self->{RESULT}=$self->{TEMP_PERLPKGS};
	}
	if($self->in_context("perlpkgs.perlpkg",$elem)) {
		$self->{TEMP_PERLPKGS}->push($self->{TEMP_PERLPKG});
	}
#	if($self->in_context("perlpkgs.perlpkg.author",$elem)) {
#		$self->SUPER::handle_end($elem);
#	}
	if($self->in_context("perlpkgs.perlpkg.author",$elem)) {
		$self->{TEMP_PERLPKG}->set_author($self->SUPER::get_result());
	}
	if($self->in_context("perlpkgs.perlpkg.modules.module",$elem)) {
		$self->{TEMP_PERLPKG}->get_modules()->push($self->{TEMP_MODULE});
	}
	if($self->in_context("perlpkgs.perlpkg.scripts.script",$elem)) {
		$self->{TEMP_PERLPKG}->get_scripts()->push($self->{TEMP_SCRIPT});
	}
	if($self->in_context("perlpkgs.perlpkg.tests.test",$elem)) {
		$self->{TEMP_PERLPKG}->get_tests()->push($self->{TEMP_TEST});
	}
	if($self->in_context("perlpkgs.perlpkg.files.file",$elem)) {
		$self->{TEMP_PERLPKG}->get_files()->push($self->{TEMP_FILE});
	}
	if($self->in_context("perlpkgs.perlpkg.credits.credit",$elem)) {
		$self->{TEMP_CREDIT}->set_author($self->SUPER::get_result());
		$self->{TEMP_PERLPKG}->get_credits()->push($self->{TEMP_CREDIT});
	}
}

sub handle_endchar($$$) {
	my($self,$elem,$name)=@_;
	$self->SUPER::handle_endchar($elem,$name);
	if($self->in_context("perlpkgs.perlpkg.name",$name)) {
		$self->{TEMP_PERLPKG}->set_name($elem);
	}
	if($self->in_context("perlpkgs.perlpkg.description",$name)) {
		$self->{TEMP_PERLPKG}->set_description($elem);
	}
	if($self->in_context("perlpkgs.perlpkg.longdescription",$name)) {
		$self->{TEMP_PERLPKG}->set_longdescription($elem);
	}
	if($self->in_context("perlpkgs.perlpkg.license",$name)) {
		$self->{TEMP_PERLPKG}->set_license($elem);
	}
	if($self->in_context("perlpkgs.perlpkg.version",$name)) {
		$self->{TEMP_PERLPKG}->set_version($elem);
	}
	if($self->in_context("perlpkgs.perlpkg.uname",$name)) {
		$self->{TEMP_PERLPKG}->set_uname($elem);
	}
	if($self->in_context("perlpkgs.perlpkg.gname",$name)) {
		$self->{TEMP_PERLPKG}->set_gname($elem);
	}
	if($self->in_context("perlpkgs.perlpkg.author",$name)) {
		#Meta::Utils::Output::print("in here\n");
		$self->SUPER::handle_endchar($elem,$name);
	}
	if($self->in_context("perlpkgs.perlpkg.modules.module.source",$name)) {
		$self->{TEMP_MODULE}->set_source($elem);
	}
	if($self->in_context("perlpkgs.perlpkg.modules.module.target",$name)) {
		$self->{TEMP_MODULE}->set_target($elem);
	}
	if($self->in_context("perlpkgs.perlpkg.scripts.script.source",$name)) {
		$self->{TEMP_SCRIPT}->set_source($elem);
	}
	if($self->in_context("perlpkgs.perlpkg.scripts.script.target",$name)) {
		$self->{TEMP_SCRIPT}->set_target($elem);
	}
	if($self->in_context("perlpkgs.perlpkg.tests.test.source",$name)) {
		$self->{TEMP_TEST}->set_source($elem);
	}
	if($self->in_context("perlpkgs.perlpkg.tests.test.target",$name)) {
		$self->{TEMP_TEST}->set_target($elem);
	}
	if($self->in_context("perlpkgs.perlpkg.files.file.source",$name)) {
		$self->{TEMP_FILE}->set_source($elem);
	}
	if($self->in_context("perlpkgs.perlpkg.files.file.target",$name)) {
		$self->{TEMP_FILE}->set_target($elem);
	}
	if($self->in_context("perlpkgs.perlpkg.credits.credit.item",$name)) {
		$self->{TEMP_CREDIT}->get_items()->push($elem);
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Xml::Parsers::Perlpkgs - Object to parse an XML/perlpkgs file.

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

	MANIFEST: Perlpkgs.pm
	PROJECT: meta
	VERSION: 0.18

=head1 SYNOPSIS

	package foo;
	use Meta::Xml::Parsers::Perlpkgs qw();
	my($def_parser)=Meta::Xml::Parsers::Perlpkgs->new();
	$def_parser->parsefile($file);
	my($def)=$def_parser->get_result();

=head1 DESCRIPTION

This object will create a Meta::Lang::Perl::Perlpkgs from an XML/perlpkgs
file.

=head1 FUNCTIONS

	new($)
	get_result($)
	handle_start($$)
	handle_end($$)
	handle_endchar($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This gives you a new object for a parser.

=item B<get_result($)>

This method will retrieve the result of the parsing process.

=item B<handle_start($$)>

This will handle start tags.

=item B<handle_end($$)>

This will handle end tags.
This currently does nothing.

=item B<handle_endchar($$)>

This will handle actual text.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Meta::Xml::Parsers::Author(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV perl packaging
	0.01 MV more perl packaging
	0.02 MV perl packaging again
	0.03 MV perl packaging again
	0.04 MV validate writing
	0.05 MV fix database problems
	0.06 MV more database issues
	0.07 MV md5 project
	0.08 MV database
	0.09 MV perl module versions in files
	0.10 MV movies and small fixes
	0.11 MV thumbnail user interface
	0.12 MV import tests
	0.13 MV more thumbnail issues
	0.14 MV website construction
	0.15 MV improve the movie db xml
	0.16 MV web site automation
	0.17 MV SEE ALSO section fix
	0.18 MV md5 issues

=head1 SEE ALSO

Meta::Development::PackModule(3), Meta::Info::Credit(3), Meta::Lang::Perl::Perlpkg(3), Meta::Lang::Perl::Perlpkgs(3), Meta::Utils::Output(3), Meta::Xml::Parsers::Author(3), strict(3)

=head1 TODO

Nothing.
