# Ginger::Reference::Shared::HTTP_Server_Simple_Wrapper
# Version 0.01
# Copyright (C) 2013 David Helkowski

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.  You may also can
# redistribute it and/or modify it under the terms of the Perl
# Artistic License.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

=head1 NAME

Ginger::Reference::Shared::HTTP_Server_Simple_Wrapper - Ginger::Reference Component

=head1 VERSION

0.01

=cut

package Ginger::Reference::Shared::HTTP_Server_Simple_Wrapper;
use base qw/HTTP::Server::Simple::CGI/;

sub set_handler {
    my $self = shift;
    my $func = shift;
    my @params = @_;
    $self->{'handler'} = $func;
    $self->{'handler_params'} = \@params;
}

sub handle_request {
    my ( $self, $cgi ) = @_;
    #print STDERR "ok\n";
    
    #print "HTTP/1.0 200 OK\r\n";
    #print $cgi->header;
    my $handler = $self->{'handler'};
    my $params = $self->{'handler_params'};
    $handler->( $cgi, @$params );
}

1;

__END__

=head1 SYNOPSIS

Component of L<Ginger::Reference>

=head1 DESCRIPTION

Component of L<Ginger::Reference>

=head1 LICENSE

  Copyright (C) 2013 David Helkowski
  
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 2 of the
  License, or (at your option) any later version.  You may also can
  redistribute it and/or modify it under the terms of the Perl
  Artistic License.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

=cut