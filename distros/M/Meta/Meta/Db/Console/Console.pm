#!/bin/echo This is a perl module and should not be run

package Meta::Db::Console::Console;

use strict qw(vars refs subs);
use Meta::Shell::Shell qw();
use Meta::Utils::Output qw();
use Meta::Db::Connections qw();
use Meta::Db::Def qw();
use Meta::Db::Dbi qw();

our($VERSION,@ISA);
$VERSION="0.18";
@ISA=qw(Meta::Shell::Shell);

#sub BEGIN();
#sub pre($);
#sub process($$);
#sub post($);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->get_set(
		-java=>"_connections",
		-java=>"_connection_name",
		-java=>"_def",
		-java=>"_dbif",
	);
}

sub pre($) {
	my($self)=@_;
	#Meta::Utils::Output::dump($self);
	my($connections)=Meta::Db::Connections->new_modu($self->get_connections());
	my($connection)=$connections->get_con_null($self->get_connection_name());
	my($def)=Meta::Db::Def->new_modu($self->get_def());
	my($dbif)=Meta::Db::Dbi->new();
	$dbif->connect_def($connection,$def);
	$self->set_dbif($dbif);
	my($attribs)=$self->Attribs;
	$attribs->{completion_entry_function}=$attribs->{list_completion_function};
	$attribs->{completion_word}=[qw(
		SELECT
		INSERT
		UPDATE
		COUNT
	)];
}

sub process($$) {
	my($self,$line)=@_;
	my($resu)=$self->get_dbif()->execute_single($line);
	my($ref)=CORE::ref($resu);
	if($ref eq "ARRAY") {
		for(my($i)=0;$i<=$#$resu;$i++) {
			Meta::Utils::Output::print("result [".$resu->[$i]."]\n");
		}
	} else {
		Meta::Utils::Output::print("result [".$resu."]\n");
	}
	$self->SUPER::process($line);
}

sub post($) {
	my($self)=@_;
	$self->SUPER::post();
	$self->get_dbif()->dis();
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Db::Console::Console - readline console for DBI/DBD databases.

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

	MANIFEST: Console.pm
	PROJECT: meta
	VERSION: 0.18

=head1 SYNOPSIS

	package foo;
	use Meta::Db::Console::Console qw();
	my($object)=Meta::Db::Console::Console->new();
	my($result)=$object->method();

=head1 DESCRIPTION

This object supplies you with a console for DBI/DBD database.
When you run the console you get to execute SQL queries and see the
results on your terminal.

=head1 FUNCTIONS

	BEGIN()
	pre($)
	process($$)
	post($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Bootstrap method to setup accessor for the following attributes:
0. connections - connections xml file.
1. connection_name - connection name.
2. def - database def file.
3. dbif - the actual database interface that will be used.

=item B<pre($)>

This method overrides the base class pre method and connects to the database.

=item B<process($$)>

This method overrides the base class process method and actually does the work
of submitting the query and printing the results.

=item B<post($)>

This method overrides the base class post method and disconnects from the database.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Meta::Shell::Shell(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV db stuff
	0.01 MV good xml support
	0.02 MV xml data sets
	0.03 MV perl packaging
	0.04 MV XSLT, website etc
	0.05 MV PDMT
	0.06 MV more movies
	0.07 MV md5 project
	0.08 MV database
	0.09 MV perl module versions in files
	0.10 MV movies and small fixes
	0.11 MV thumbnail user interface
	0.12 MV more thumbnail issues
	0.13 MV website construction
	0.14 MV web site automation
	0.15 MV SEE ALSO section fix
	0.16 MV download scripts
	0.17 MV teachers project
	0.18 MV md5 issues

=head1 SEE ALSO

Meta::Db::Connections(3), Meta::Db::Dbi(3), Meta::Db::Def(3), Meta::Shell::Shell(3), Meta::Utils::Output(3), strict(3)

=head1 TODO

-add options to set the prompt according to preference.

-use Data::ShowTable to show the results.
