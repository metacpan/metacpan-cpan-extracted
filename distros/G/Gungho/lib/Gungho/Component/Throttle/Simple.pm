# $Id: /mirror/gungho/lib/Gungho/Component/Throttle/Simple.pm 31301 2007-11-29T11:51:44.807693Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Component::Throttle::Simple;
use strict;
use warnings;
use base qw(Gungho::Component::Throttle::Throttler);

sub setup
{
    my $self = shift;

    my $config  = $self->config->{throttle}{simple};

    $self->prepare_throttler(
        map { ($_ => $config->{$_}) }
            qw(max_items interval db_file throttler cache)
    );
    $self->next::method(@_);
}

sub throttle
{
    my $c = shift;
    my $request = shift;
    my $t = $c->throttler;

    if ( ! $t->try_push() ) {
        $c->log->debug("[THROTTLE] " . $request->uri . " throttled by Throttle::Simple");
        return ();
    }

    return $c->next::method($request);
}

1;

__END__

=head1 NAME

Gungho::Component::Throttle::Simple - Throttle By Number Of Requests

=head1 SYNOPSIS

  ---
  throttle:
    simple:
      max_items 1000
      interval: 3600
  components:
    - Throttle::Simple

=head1 METHODS

=head2 setup

=head2 throttle($request)

Checks if a request can be executed succesfully. Returns 1 if it's ok to
execute the request.

=cut
