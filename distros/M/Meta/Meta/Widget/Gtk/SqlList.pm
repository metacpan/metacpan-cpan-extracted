#!/bin/echo This is a perl module and should not be run

package Meta::Widget::Gtk::SqlList;

use strict qw(vars refs subs);
use Gtk qw();
use SQL::Statement qw();

our($VERSION,@ISA);
$VERSION="0.13";
@ISA=qw(Gtk::CList);

#sub new_statement($$$$);
#sub refresh($);
#sub TEST($);

#__DATA__

sub new_statement($$$$) {
	my($clas,$dbi,$sql,$def)=@_;
	# parse the statement to get the number of columns
	my($stmt)=SQL::Statement->new($sql);
	my($num_columns);
	$num_columns=$stmt->columns();
	# create the CList widget with the correct number of columns
	my($self)=Gtk::CList->new($num_columns);
	bless($self,$clas);
	$self->column_titles_show();
	# set the attributes for later reference
	$self->{DBI}=$dbi;
	$self->{SQL}=$sql;
	$self->{DEF}=$def;
	# add the columns
	my(@columns)=$stmt->columns();
	for(my($i)=0;$i<$num_columns;$i++) {
		my($ccol)=$columns[$i];
		my($cnam)=$ccol->name();
		my($ctab)=$ccol->table();
		$self->set_column_title($i,$cnam);
	}
	#refresh to get all the items in
	$self->refresh();
	return($self);
}

sub refresh($) {
	my($self)=@_;
	$self->clear();
#	my($list)=$self->get_dbi()->execute_prep($self->get_prep());
	my($list)=$self->{DBI}->execute_arrayref($self->{SQL});
	for(my($i)=0;$i<=$#$list;$i++) {
		my($curr)=$list->[$i];
		$self->append(@$curr);
	}
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Widget::Gtk::SqlList - a CList widget that displays result of an SQL query.

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

	MANIFEST: SqlList.pm
	PROJECT: meta
	VERSION: 0.13

=head1 SYNOPSIS

	package foo;
	use Meta::Widget::Gtk::SqlList qw();
	my($object)=Meta::Widget::Gtk::SqlList->new($def,);
	my($result)=$object->refresh();

=head1 DESCRIPTION

Create this widget, assign an SQL statement to it and forget about it.
The widget will:
0. prepare the statement so issueing refreshes to it will be easier.
1. will handle the right button mouse click and will offer the
	user the option to refresh whenever the mouse is on top
	of it.
2. will parse the SQL statement given to it and will create the columns
	of the list accoding to the columns which are returned
	from the query.
3. will display hints on column names according to descriptions in the
	database schema.
4. if the database updates and can send signals, this widget will
	automatically update the information in its display.

This now uses the new SQL::Statment version by Jeff Zucker (better).

=head1 FUNCTIONS

	new_statement($$$$)
	refresh($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new_statement($$$$)>

This is a constructor for the Meta::Widget::Gtk::SqlList object.
This is the constructor you should use since it gets all the parameters needed
for correct construction.

=item B<refresh($)>

This method will rerun the quest and will refresh the display.
It does so by first clearing the display, then issueing the prepared
statement and then appending all results to the widget.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Gtk::CList(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV advance the contacts project
	0.01 MV xml/rpc client/server
	0.02 MV perl packaging
	0.03 MV md5 project
	0.04 MV database
	0.05 MV perl module versions in files
	0.06 MV movies and small fixes
	0.07 MV thumbnail user interface
	0.08 MV more thumbnail issues
	0.09 MV website construction
	0.10 MV web site automation
	0.11 MV SEE ALSO section fix
	0.12 MV weblog issues
	0.13 MV md5 issues

=head1 SEE ALSO

Gtk(3), SQL::Statement(3), strict(3)

=head1 TODO

-add the prepare stuff.
