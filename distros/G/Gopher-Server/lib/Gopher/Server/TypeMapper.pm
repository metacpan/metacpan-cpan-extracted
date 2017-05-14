
package Gopher::Server::TypeMapper;
use strict;
use warnings;

use overload q("") => \&as_string;

# Constants
sub GOPHER_TYPE () { 0 }
sub MIME_TYPE   () { 1 }
sub TYPES       () {{
	txt        => [  '0', 'text/plain'        ], 
	directory  => [  '1', ''                  ], 
	default    => [  '9', 'application/data'  ], 
}}


sub get_type 
{
	my ($class, $in) = @_;

	my $ext = $in->{extention} ? $in->{extention} : '';
	unless($ext) {
		my $filename = $in->{filename} 
			or die "Need a filename or extention";

		if( -d $filename ) {
			$ext = 'directory';
		}
		else {
			($ext) = $filename =~ / \. (\w+) \z/x;
		}
	}

	no warnings; # Shut off warnings for case where $ext isn't defined
	my $self = exists TYPES->{$ext} ? TYPES->{$ext} : TYPES->{default};
	bless $self => $class;
}


sub gopher_type  {  $_[0]->[GOPHER_TYPE]  }
sub mime_type    {  $_[0]->[MIME_TYPE]    }

sub as_string    {  $_[0]->gopher_type    }


1;
__END__

=head1 NAME 

  Gopher::Server::TypeMapper - Map a file to a Gopher type/MIME type'

=head1 SYNOPSIS

=head1 DESCRIPTION

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

