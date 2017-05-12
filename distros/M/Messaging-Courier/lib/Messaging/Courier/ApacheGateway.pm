package Messaging::Courier::ApacheGateway;

use strict;
use warnings;

use Apache;
use Courier;
use Messaging::Courier::Frame;
use Apache::Request;
use Apache::Constants qw( :common );

sub handle {
  my $request = shift;

  my $c     = Courier->new();
  my $m     = Messaging::Courier::Frame->new_with_frame( $request->content );
  my $reply = $c->ask( $m->content() );

  print $reply->frame->serialize();

  return OK;
}


1;
