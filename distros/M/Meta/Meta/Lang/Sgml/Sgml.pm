#!/bin/echo This is a perl module and should not be run

package Meta::Lang::Sgml::Sgml;

use strict qw(vars refs subs);
use Meta::Xml::Parsers::Deps qw();
use Meta::Baseline::Aegis qw();
use Meta::Utils::Env qw();

our($VERSION,@ISA);
$VERSION="0.07";
@ISA=qw();

#sub catalog_setup();
#sub get_prefix();
#sub c2deps($);
#sub TEST($);

#__DATA__

sub catalog_setup() {
	my($path)=Meta::Baseline::Aegis::search_path_list();
	my($value)=$path->get_catenate(":","dtdx/CATALOG");
	Meta::Utils::Env::set("SGML_CATALOG_FILES",$value);
}

sub get_prefix() {
	return("chun/sgml/");
}

sub c2deps($) {
	my($buil)=@_;
	my($parser)=Meta::Xml::Parsers::Deps->new();
	$parser->set_doctype_prefix("dtdx/");
	$parser->set_do_doctype(1);
	$parser->set_externent_prefix(&get_prefix());
	$parser->set_do_externent(1);
	$parser->set_root($buil->get_modu());
	$parser->parsefile($buil->get_srcx());
	return($parser->get_deps());
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Lang::Sgml::Sgml - help you with Sgml related tasks.

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

	MANIFEST: Sgml.pm
	PROJECT: meta
	VERSION: 0.07

=head1 SYNOPSIS

	package foo;
	use Meta::Lang::Sgml::Sgml qw();
	my($object)=Meta::Lang::Sgml::Sgml->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This class will help you with Sgml related tasks.
0. Producing dependency information for an Sgml file.

=head1 FUNCTIONS

	catalog_setup()
	get_prefix()
	c2deps($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<catalog_setup()>

This method will set the SGML_CATALOG_FILES environment variable correctly
according to the Aegis search path. Some SGML related tools need this
variable set correctly in order to find SGML catalog files.

=item B<get_prefix()>

This method returns the prefix for Sgml related material in the baseline.

=item B<c2deps($)>

This method reads a source xml file and produces a deps object which describes
the dependencies for that file.
This method uses an Expat parser to do it which is quite cheap.

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

	0.00 MV more Class method generation
	0.01 MV thumbnail user interface
	0.02 MV more thumbnail issues
	0.03 MV website construction
	0.04 MV web site automation
	0.05 MV SEE ALSO section fix
	0.06 MV finish papers
	0.07 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Utils::Env(3), Meta::Xml::Parsers::Deps(3), strict(3)

=head1 TODO

Nothing.
