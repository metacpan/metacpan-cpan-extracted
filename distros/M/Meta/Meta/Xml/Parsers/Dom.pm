#!/bin/echo This is a perl module and should not be run

package Meta::Xml::Parsers::Dom;

use strict qw(vars refs subs);
use XML::DOM qw();
use Meta::Utils::Output qw();
use Meta::Baseline::Aegis qw();
use Meta::Utils::File::File qw();

our($VERSION,@ISA);
$VERSION="0.02";
@ISA=qw(XML::DOM::Parser);

#sub new($);
#sub handle_externent($$$$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)=XML::DOM::Parser->new();
	if(!$self) {
		throw Meta::Error::Simple("didn't get a parser");
	}
	$self->setHandlers(
		'ExternEnt'=>\&handle_externent,
	);
	bless($self,$class);
	return($self);
}

sub handle_externent($$$$) {
	my($self,$base,$sysi,$pubi)=@_;
	$sysi="chun/sgml/".$sysi;
	my($find)=Meta::Baseline::Aegis::which($sysi);
	my($data);
	Meta::Utils::File::File::load($find,\$data);
	#Meta::Utils::Output::print("in handle_externent\n");
	#Meta::Utils::Output::print("base is [".$base."]\n");
	#Meta::Utils::Output::print("sysi is [".$sysi."]\n");
	#Meta::Utils::Output::print("pubi is [".$pubi."]\n");
	return($data);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Xml::Parsers::Dom - an XML/DOM parser class.

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

	MANIFEST: Dom.pm
	PROJECT: meta
	VERSION: 0.02

=head1 SYNOPSIS

	package foo;
	use Meta::Xml::Parsers::Dom qw();
	my($def_parser)=Meta::Xml::Parsers::Dom->new();
	$def_parser->parsefile($file);
	my($def)=$def_parser->get_result();

=head1 DESCRIPTION

This is a Dom class for baseline XML files. The reason
we cannot use the original XML::DOM::Parser is because
of external file resolution which should be done according
to the search path and that is precisely the only method
which is derived here over the regular checker.

=head1 FUNCTIONS

	new($)
	handle_externent($$$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This gives you a new object for a parser.

=item B<handle_externent($$$$)>

This method will handle resolving external references.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

XML::DOM::Parser(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV web site automation
	0.01 MV SEE ALSO section fix
	0.02 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Utils::File::File(3), Meta::Utils::Output(3), XML::DOM(3), strict(3)

=head1 TODO

Nothing.
