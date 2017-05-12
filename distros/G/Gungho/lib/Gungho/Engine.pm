# $Id: /mirror/gungho/lib/Gungho/Engine.pm 31637 2007-12-01T14:04:35.046822Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Engine;
use strict;
use warnings;
use base qw(Gungho::Base);

__PACKAGE__->mk_virtual_methods($_) for qw(run stop);

sub finish_request
{
    my ($self, $c, $request) = @_;
    if (my $host = $request->notes('original_host')) {
        # Put it back
        $request->uri->host($host);
    }
}

sub handle_response
{
    my ($self, $c, $request, $response) = @_;
    $self->finish_request($c, $request);
    $c->handle_response($request, $response);
}

sub handle_dns_response
{
    my ($self, $c, $request, $dns_response) = @_;

    if (! $dns_response) {
        return;
    }

    foreach my $answer ($dns_response->answer) {
        next unless $answer->type eq 'A';
        return if $c->handle_dns_response($request, $answer, $dns_response);
    }

    $c->handle_response($request, $c->_http_error(500, "Failed to resolve host " . $request->uri->host, $request)),
}

1;

__END__

=head1 NAME

Gungho::Engine - Base Class For Gungho Engine

=head1 SYNOPSIS

  package Gungho::Engine::SomeEngine;
  use strict;
  use base qw(Gungho::Engine);

  sub run
  {
     ....
  }

=head1 METHODS

=head2 handle_dns_response()

Handles the response from DNS lookups.

=head2 handle_response

Call finish_request() on the request, and delegates to Gungho's
hnalde_response()

=head2 finish_request

Perform whatever cleanup required on the request

=head2 run()

Starts the engine. The exact behavior differs between each engines

=head2 stop()

Stops the engine.  The exact behavior differs between each engines

=cut
