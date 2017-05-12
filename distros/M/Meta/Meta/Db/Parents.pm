#!/bin/echo This is a perl module and should not be run

package Meta::Db::Parents;

use strict qw(vars refs subs);
use Meta::Ds::Ochash qw();
use Meta::Ds::Connected qw();

our($VERSION,@ISA);
$VERSION="0.14";
@ISA=qw(Meta::Ds::Ochash Meta::Ds::Connected);

#sub printd($$);
#sub printx($$);
#sub getsql_crea($$$);
#sub getsql_drop($$$$);
#sub getsql_clean($$$);
#sub getsql_select($$$);
#sub getsql_insert($$$);
#sub TEST($);

#__DATA__

sub printd($$) {
	my($self,$writ)=@_;
	$writ->dataElement("title","Parents");
	$writ->startTag("para");
	if($self->size()>0) {
		$writ->startTag("itemizedlist");
		for(my($i)=0;$i<$self->size();$i++) {
			$writ->startTag("listitem");
			$writ->dataElement("para",$self->elem($i)->get_name());
			#$self->elem($i)->printd($writ);
			$writ->endTag("listitem");
		}
		$writ->endTag("itemizedlist");
	} else {
		$writ->characters("No Parents are defined for this database");
	}
	$writ->endTag("para");
}

sub printx($$) {
	my($self,$writ)=@_;
	if($self->size()>0) {
		$writ->startTag("parents");
		for(my($i)=0;$i<$self->size();$i++) {
			$writ->dataElement("parent",$self->elem($i)->get_name());
		}
		$writ->endTag("parents");
	}
}

sub getsql_crea($$$) {
	my($self,$stats,$info)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		$self->elem($i)->getsql_crea($stats,$info);
	}
}

sub getsql_drop($$$$) {
	my($self,$stats,$info,$prim)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		$self->elem($i)->getsql_drop($stats,$info,$prim);
	}
}

sub getsql_clean($$$) {
	my($self,$stats,$info)=@_;
	for(my($i)=0;$i<$self->size();$i++) {
		$self->elem($i)->getsql_clean($stats,$info);
	}
}

sub getsql_select($$$) {
	my($self,$info,$table)=@_;
	my(@arra);
	for(my($i)=0;$i<$self->size();$i++) {
		push(@arra,$self->elem($i)->getsql_select($info,$table));
	}
#	Meta::Utils::Output::print("size is [".$#arra."]\n");
	my($res)=join(",",@arra);
#	Meta::Utils::Output::print("select returning [".$res."]\n");
	return($res);
}

sub getsql_insert($$$) {
	my($self,$info,$table)=@_;
	my(@arra);
	for(my($i)=0;$i<$self->size();$i++) {
		push(@arra,$self->elem($i)->getsql_insert($info,$table));
	}
#	Meta::Utils::Output::print("size is [".$#arra."]\n");
	my($res)=join(",",@arra);
#	Meta::Utils::Output::print("insert returning [".$res."]\n");
	return($res);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Db::Parents - Object to store a hash of Parent objects for a database.

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

	MANIFEST: Parents.pm
	PROJECT: meta
	VERSION: 0.14

=head1 SYNOPSIS

	package foo;
	use Meta::Db::Parents qw();
	my($enums)=Meta::Db::Parents->new();
	my($user)=$users->get("mark");

=head1 DESCRIPTION

This is an object to store a list of Parent objects for a database.

=head1 FUNCTIONS

	printd($$)
	printx($$)
	getsql_crea($$$)
	getsql_drop($$$$)
	getsql_clean($$$)
	getsql_select($$$)
	getsql_insert($$$)
	TEST($);

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<printd($$)>

This method will print the object to DocBook XML using the a writer
object received.

=item B<printx($$)>

This method will print the object to XML using the a writer
object received.

=item B<getsql_crea($$$)>

This method receives a Parents object and a collection of Sql statements.
The method adds to that collection SQL statements to create this set of
db parents.

=item B<getsql_drop($$$$)>

This method receives a Parents object and a collection of Sql statements.
The method adds to that collection SQL statements to drop this set of db
parents.

=item B<getsql_clean($$$)>

This method receives a Parents object and a collection of Sql statements.
The method adds to that collection SQL statements to clean this set of
db parents.

=item B<getsql_select($$$)>

This method returns an SQL sniplet which can be used in SELECT type statements.

=item B<getsql_insert($$$)>

This method returns an SQL sniplet which can be used in INSERT type statements.

=item B<TEST($)>

Test suite for this object.

=back

=head1 SUPER CLASSES

Meta::Ds::Ochash(3), Meta::Ds::Connected(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV PDMT
	0.01 MV some chess work
	0.02 MV md5 project
	0.03 MV database
	0.04 MV perl module versions in files
	0.05 MV movies and small fixes
	0.06 MV movie stuff
	0.07 MV graph visualization
	0.08 MV thumbnail user interface
	0.09 MV more thumbnail issues
	0.10 MV website construction
	0.11 MV web site automation
	0.12 MV SEE ALSO section fix
	0.13 MV teachers project
	0.14 MV md5 issues

=head1 SEE ALSO

Meta::Ds::Connected(3), Meta::Ds::Ochash(3), strict(3)

=head1 TODO

Nothing.
