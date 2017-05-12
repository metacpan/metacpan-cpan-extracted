# $Id: /mirror/gungho/lib/Gungho/Handler.pm 31310 2007-11-29T13:19:42.807767Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Handler;
use strict;
use warnings;
use base qw(Gungho::Base);
use Gungho::Request;

__PACKAGE__->mk_virtual_methods($_) for qw(handle_response);

sub stop {}

1;

=head1 NAME

Gungho::Handler - Base Class For Gungho Handlers

=head1 SYNOPSIS

  sub handle_response
  {
     my ($self, $c, $request, $response) = @_;
  }

=head1 METHODS

=head2 handle_response($c, $request, response)

This is where you want to process the response.

=head2 stop($reason)

Stop the Handler. Place code that needs to be executed to shutdown the
handler here.

=cut
