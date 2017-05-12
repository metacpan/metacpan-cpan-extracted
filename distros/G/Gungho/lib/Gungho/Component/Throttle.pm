# $Id: /mirror/gungho/lib/Gungho/Component/Throttle.pm 31302 2007-11-29T11:52:09.725591Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>

package Gungho::Component::Throttle;
use strict;
use warnings;
use base qw(Gungho::Component);

sub feature_name { 'Throttle' }

sub throttle
{
    my $c = shift;
    $c->log->debug( $_[0]->url . " NOT throttled" );
    return 1;
}

sub send_request
{
    my ($c, $request) = @_;

    if (! $request->notes('original_host') && ! $c->throttle($request)) {
        $c->log->debug("[THROTTLE] Request " . $request->url . " (" . $request->id . ") was throttled");
        $c->pushback_request($request);
        return 0;
    } else {
        return $c->next::method($request);
    }
}

1;

__END__

=head1 NAME

Gungho::Component::Throttle - Base Class To Throttle Requests

=head1 SYNOPSIS

  package Gungho::Component::Throttle::Domain;
  use base qw(Gungho::Component::Throttle);

=head1 DESCRIPTION

If you create a serious enough crawler, throttling will become a major issue.
After all, you want to *crawl* the sites, not overwhelm them with requests.

While the concept is simple, implementing this on your own is relatively 
costly, so Gungho provides a few simple ways to work with this problem.

Gungho::Component::Throttle::Simple will throttle simply by the number of
requests being sent at a time, regardless of what they are. This simple
approach will work well if your client-side resources are limited -- for
example, you don't want your requests to hog up too much bandwidth, so
you limit the actual number of requests being sent.

  # throttle down to 100 requests / hour
  components:
    - Throttle::Simple
  throttle:
    simple:
      max_iterms: 100
      interval: 3600

In most cases, however, you will probably want Gungho::Component::Throttle::Domain,
which throttles requests on a per-domain basis. This way you can, for example,
limit the number of requests being sent to one host, while letting the remaining
time slices to be used against some other host.

  # throttle down to 100 requests / host / hour
  components:
    - Throttle::Domain
  throttle:
    domain:
      max_iterms: 100
      interval: 3600

This component utilises Data::Throttler or Data::Throttler::Memcached for the
main engine to keep track of the throttling. Data::Throttler will suffice
if you are working from a single host. You will need Data::Throttler::Memcached if you have a farm of crawlers that may potentially be residing on different
hosts.

By default Data::Throttler will be used. If you want to override this, specify
the throttler argument in the configuration:

  components:
    - Throttle::Domain
  throttle:
    domain:
      throttler: Data::Throttler::Memcached
      cache:
        data: 127.0.0.1:11211
      max_items: 100
      interval: 3600

Starting from 0.09003, you can stack throttlers. For example, you can throttle
by Throttle::Simple first, and if Throttle::Simple allowed the request to
go, then you can  throttle with Throttle::Domain as well to make sure that
the same host doesn't get beaten up.

=head1 METHODS

=head2 feature_name

=head2 throttle

=head2 send_request

=cut