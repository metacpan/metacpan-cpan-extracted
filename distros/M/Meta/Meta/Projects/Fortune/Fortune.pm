#!/bin/echo This is a perl module and should not be run

package Meta::Projects::Fortune::Fortune;

use strict qw(vars refs subs);
use Meta::Db::Connections qw();
use Meta::Db::Dbi qw();
use Meta::Development::Module qw();

our($VERSION,@ISA);
$VERSION="0.02";
@ISA=qw();

#sub new($$$$);
#sub random($);
#sub random_cat($$);
#sub TEST($);

#__DATA__

sub new($$$$) {
	my($clas,$connections_file,$con_name,$name)=@_;
	my($self)={};
	CORE::bless($self,$clas);

	my($module)=Meta::Development::Module->new_name($connections_file);
	my($connections)=Meta::Db::Connections->new_modu($module);
	my($connection)=$connections->get_con_null($con_name);
	my($dbi)=Meta::Db::Dbi->new();
	$dbi->connect_name($connection,$name);
	$self->{DBI}=$dbi;

	return($self);
}

sub random($) {
	my($self)=@_;
	my($stat)="select text from item order by rand() limit 1";
	my($dbi)=$self->{DBI};
	my($res)=$dbi->execute_arrayref($stat);
	my($data)=$res->[0]->[0];
	return($data);
}

sub random_cat($$) {
	my($self,$name)=@_;
	my($stat)="select text from item,link,node where item.id=link.item_id and link.node_id=node.id and node.name='".$name."' order by rand() limit 1";
	my($dbi)=$self->{DBI};
	my($res)=$dbi->execute_arrayref($stat);
	my($data)=$res->[0]->[0];
	return($data);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Projects::Fortune::Fortune - provide fortune services.

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

	MANIFEST: Fortune.pm
	PROJECT: meta
	VERSION: 0.02

=head1 SYNOPSIS

	package foo;
	use Meta::Projects::Fortune::Fortune qw();
	my($fortune)=Meta::Projects::Fortune::Fortune->new([connection data]);
	my($random_fortune)=$fortune->random();

=head1 DESCRIPTION

This class provides fortune services. Examples are providing you with
a random fortune saying, providing you with a fortune saying under
a specific category etc...

=head1 FUNCTIONS

	new($$$$)
	random($)
	random_cat($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($$$$)>

This is a constructor for the Meta::Projects::Fortune::Fortune object.
Data to make a connection need to be supplied.

=item B<random($)>

Provide a random fortune saying.

=item B<random_cat($$)>

Provide you with a random fortune saying out of a specific category.

=item B<TEST($)>

This is a testing suite for the Meta::Projects::Fortune::Fortune module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

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

	0.00 MV finish papers
	0.01 MV teachers project
	0.02 MV md5 issues

=head1 SEE ALSO

Meta::Db::Connections(3), Meta::Db::Dbi(3), Meta::Development::Module(3), strict(3)

=head1 TODO

-prepare the statements in the constructor.

-start using Class::DBI instead of doing SQL stuff here.
