
package Gopher::Server::RequestHandler::DBI;
use strict;
use warnings;
use base 'Gopher::Server::RequestHandler';

sub new 
{
	my ($class, $request) = @_;
	die "Not yet implemented";
}

1;
__END__

=head1 NAME 

  Gopher::Server::RequestHandler::DBI - Use a database to process a gopher request

=head1 DESCRIPTION

This is an implementation of a RequestHandler that uses a database to 
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

