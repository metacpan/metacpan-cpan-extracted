#!/bin/echo This is a perl module and should not be run

package Meta::Widget::Gtk::DirTree;

use strict qw(vars refs subs);
use Gtk qw();

our($VERSION,@ISA);
$VERSION="0.06";
@ISA=qw(Gtk::Tree);

#sub new($);
#sub set_root($);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)=Gtk::Tree->new();
	$self->{ROOT}=defined;
	bless($self,$class);
	return($self);
}

sub set_root($$) {
	my($self,$val)=@_;
	$self->{ROOT}=$val;
	#lets add the root element
	#$self->node_add($node,$self,$self);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Widget::Gtk::DirTree - widget to show you parts of the file system.

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

	MANIFEST: DirTree.pm
	PROJECT: meta
	VERSION: 0.06

=head1 SYNOPSIS

	package foo;
	use Meta::Widget::Gtk::DirTree qw();
	my($object)=Meta::Widget::Gtk::DirTree->new();
	my($result)=$object->set_root("/");

=head1 DESCRIPTION

This is a Widget which inherits from the Gtk::Tree widget and which shows
a part of the file system in it,

=head1 FUNCTIONS

	new($)
	set_root($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This is a constructor for the Meta::Widget::Gtk::DirTree object.

=item B<set_root($)>

This method will set the root which will be displayed in the widget.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Gtk::Tree(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV graph visualization
	0.01 MV thumbnail user interface
	0.02 MV more thumbnail issues
	0.03 MV website construction
	0.04 MV web site automation
	0.05 MV SEE ALSO section fix
	0.06 MV md5 issues

=head1 SEE ALSO

Gtk(3), strict(3)

=head1 TODO

-add capability for the widget to save/load state information (which nodes are open).
