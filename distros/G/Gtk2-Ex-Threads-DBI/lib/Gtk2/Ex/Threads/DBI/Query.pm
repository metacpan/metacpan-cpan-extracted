package Gtk2::Ex::Threads::DBI::Query;

# This is just a query handle object used by Gtk2::Ex::Threads::DBI
use strict;
use warnings;

sub new {
	my ($class, $name, $thread) = @_;
	my $self  = {};
	bless ($self, $class);
	$self->{id} = $name;
	$self->{thread} = $thread;
	return $self;
}

sub execute {
	my ($self, $sqlparams) = @_;
	$self->{thread}->execute($self->{id}, $sqlparams);
}

1;

=head1 AUTHOR

Ofey Aikon, C<< <ofey.aikon at gmail dot com> >>

=head1 ACKNOWLEDGEMENTS

To the wonderful gtk-perl-list.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Ofey Aikon, All Rights Reserved.

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 59
Temple Place - Suite 330, Boston, MA  02111-1307  USA.

=cut