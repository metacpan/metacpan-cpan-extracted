#!/bin/echo This is a perl module and should not be run

package Meta::Pdmt::TimeNode;

use strict qw(vars refs subs);
use Meta::Pdmt::Node qw();
use Error qw(:try);

our($VERSION,@ISA);
$VERSION="0.01";
@ISA=qw(Meta::Pdmt::Node);

#sub mtime($);
#sub uptodate($$);
#sub TEST($);

#__DATA__

sub mtime($) {
	my($self)=@_;
	throw Meta::Error::Simple("this mtime method must be over ridden");
	return(1);
}

sub uptodate($$) {
	my($self,$pdmt)=@_;
	#get all nodes which this edge depends on
	my($date)=$self->mtime();
	my(@nodes)=$pdmt->successors($self);
	for(my($i)=0;$i<=$#nodes;$i++) {
		my($curr)=$nodes[$i];
		if($curr->mtime()>$date) {
			return(0);
		}
	}
	return(1);
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Pdmt::TimeNode - A node which has a modification time.

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

	MANIFEST: TimeNode.pm
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	package foo;
	use Meta::Pdmt::TimeNode qw();
	my($object)=Meta::Pdmt::TimeNode->new();
	my($result)=$object->method();

=head1 DESCRIPTION

All nodes which can report some kind of modification time should inherit from
this node.

=head1 FUNCTIONS

	mtime($)
	uptodate($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<mtime($)>

This is the method which reports the modification time of the node.
This method should be overriden in inherited classes.

=item B<uptodate($$)>

This method reports whether the node is up to date by comparing it's
modification time with that of it's ingridients.

=item B<TEST($)>

This is a testing suite for the Meta::Pdmt::TimeNode module.
This test is should be run by a higher level management system at integration
or release time or just as a regular routine to check that all is well.

This test currently does nothing.

=back

=head1 SUPER CLASSES

Meta::Pdmt::Node(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV teachers project
	0.01 MV md5 issues

=head1 SEE ALSO

Error(3), Meta::Pdmt::Node(3), strict(3)

=head1 TODO

Nothing.
