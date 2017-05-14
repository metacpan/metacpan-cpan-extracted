
package Gopher::Server::Response;
use strict; 
use warnings;


sub new 
{
	my ($class, $in) = @_;
	die "Need a hashref" unless ref $in eq 'HASH';

	my $request = $in->{request} 
		or die "Need a request to give a response to";
	my $self = {
		request             => $request, 
		gopher_plus         => $in->{gopher_plus}, 
		fh                  => $in->{fh}, 
		information_blocks  => $in->{information_blocks}, 
		menu_items          => $in->{menu_items}, 
	};
	bless $self, $class;
}


sub print_to 
{
	my $self  = shift;
	my $fh    = shift || *STDOUT;

	if($self->{fh}) {
		$self->_print_filehandle( $fh );
	}
	elsif($self->{menu_items}) {
		$self->_print_menu( $fh );
	}
	elsif($self->{information_blocks}) {
		$self->_print_info( $fh );
	}
	else {
		die "Don't have anything to print!";
	}
}

sub _print_filehandle 
{
	my ($self, $fh) = @_;
	my $in = $self->{fh};

	while( read( $in, my $buf, 8192 ) ) {
		print $fh $buf;
	}
}

sub _print_menu 
{
	my ($self, $fh) = @_;

	foreach my $menu_item (@{ $self->{menu_items} }) {
		print $fh $menu_item->as_string, "\r\n";
	}

	print $fh ".\r\n";
}

sub _print_info 
{
	my ($self, $fh) = @_;
}


sub request { $_[0]->{request} }

1;
__END__


=head1 NAME 

  Gopher::Server::Response -- A server response for Gopher requests 

=head1 SYNOPSIS 

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR 

  Timm Murray
  CPAN ID: TMURRAY
  E-Mail: tmurray@cpan.org
  Homepage: http://www.wumpus-cave.net

=head1 LICENSE 

Gopher::Server
Copyright (C) 2004  Timm Murray

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut

