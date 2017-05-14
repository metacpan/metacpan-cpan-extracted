
package Gopher::Server::RequestHandler::File;
use strict;
use warnings;
use Gopher::Server::Response;
use base 'Gopher::Server::RequestHandler';


sub new 
{
	my ($class, $in) = @_;

	die "Need a hashref" unless ref($in) eq 'HASH';

	my $root = $in->{root} || die "Need a root for the server";
	my $host = $in->{host} || die "Need a host for the server";
	my $port = $in->{port} || die "Need a port for the server";

	my $self = {
		root => $root, 
		host => $host, 
		port => $port, 
	};
	bless $self, $class;
}

sub root { $_[0]->{root} }


sub process 
{
	my ($self, $request) = @_;

	my $path = $self->_canonpath( $request->selector );

	my $response;
	if( -d $path ) { # Directory, send back menu
		$response = $self->_make_menu( $path, $request );
	}
	elsif( -e $path ) { # File, return its contents
		$response = $self->_make_file( $path, $request );
	}
	else { # Nothing found
	}

	return $response;
}


sub _canonpath 
{
	my $self = shift;
	my $want = shift || '/';
	my $root = $self->root;

	use File::Spec;
	my @splitpath = File::Spec->splitdir($want);
	my @splitpath_clean = File::Spec->no_upwards(@splitpath);
	return File::Spec->canonpath( 
		File::Spec->join( $root, @splitpath_clean ) 
	);
}

sub _make_menu 
{
	my ($self, $path, $request) = @_;

	my $selector = $request->selector;
	opendir( my $dir, $path ) or die "Can't open directory $path: $!\n";

	my @menu_items;
	foreach my $dir_item (readdir($dir)) {
		use Gopher::Server::TypeMapper;
		my $item_type = Gopher::Server::TypeMapper->get_type({
			filename => "$path/$dir_item", 
		});

		use Net::Gopher::Response::MenuItem;
		my $item_selector = $selector . "/$dir_item";
		push @menu_items, Net::Gopher::Response::MenuItem->new({
			#request      => $request, 
			ItemType     => $item_type->gopher_type, 
			Display      => $dir_item,
			Selector     => $item_selector,
			Host         => $self->{host}, 
			Port         => $self->{port},
		});
	}

	return Gopher::Server::Response->new({
		request     => $request, 
		menu_items  => \@menu_items, 
	});
}

sub _make_file 
{
	my ($self, $path, $request) = @_;

	open(my $fh, '<', $path) or die "Can't open $path: $!\n";

	return Gopher::Server::Response->new({
		request  => $request, 
		fh       => $fh, 
	});
}


1;
__END__

=head1 NAME 

  Gopher::Server::RequestHandler::File - Use a filesystem to process a gopher request

=head1 DESCRIPTION

This is an implementation of a RequestHandler that uses the filesystem to 
determine what should be returned.

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

