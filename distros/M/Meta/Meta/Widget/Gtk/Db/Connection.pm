#!/bin/echo This is a perl module and should not be run

package Meta::Widget::Gtk::Db::Connection;

use strict qw(vars refs subs);
use Gtk qw();

our($VERSION,@ISA);
$VERSION="0.12";
@ISA=qw(Gtk::Window);

#sub new($);
#sub event_delete_event($$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)=Gtk::Window->new("dialog");
	bless($self,$class);
	#this is where the create code comes in
	$self->signal_connect("delete_event",\&event_delete_event);
	my($name_label)=Gtk::Label->new();
	$name_label->set_text("name");
	my($name_entry)=Gtk::Entry->new();
	my($type_label)=Gtk::Label->new();
	$type_label->set_text("type");
	my($host_label)=Gtk::Label->new();
	$host_label->set_text("host");
	my($packer)=Gtk::VBox->new(0,0);
	$packer->pack_start_defaults($name_label);
	$packer->pack_start_defaults($type_label);
	$packer->pack_start_defaults($host_label);
	$packer->pack_start_defaults($name_entry);
	$name_label->show();
	$type_label->show();
	$host_label->show();
	$name_entry->show();
	$self->add($packer);
	$packer->show();
	return($self);
}

sub event_delete_event($$) {
	my($self,$data)=@_;
	Gtk->exit(0);
	return(0);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Widget::Gtk::Db::Connection - widget to edit database connection informatin.

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

	MANIFEST: Connection.pm
	PROJECT: meta
	VERSION: 0.12

=head1 SYNOPSIS

	package foo;
	use Meta::Widget::Gtk::Db::Connection;
	my($window)=Meta::Widget::Gtk::Db::Connection->new();
	$window->show();

=head1 DESCRIPTION

This object inherits from a gtk window and when created, will create a window
which edits a connection information.

=head1 FUNCTIONS

	new($)
	event_delete_event($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This gives you a new object for a parser.

=item B<event_delete_event($$)>

This is the "delete_event" handler.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Gtk::Window(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV perl reorganization
	0.01 MV perl packaging
	0.02 MV md5 project
	0.03 MV database
	0.04 MV perl module versions in files
	0.05 MV movies and small fixes
	0.06 MV graph visualization
	0.07 MV thumbnail user interface
	0.08 MV more thumbnail issues
	0.09 MV website construction
	0.10 MV web site automation
	0.11 MV SEE ALSO section fix
	0.12 MV md5 issues

=head1 SEE ALSO

Gtk(3), strict(3)

=head1 TODO

Nothing.
