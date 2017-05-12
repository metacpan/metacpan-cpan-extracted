use strict;
use warnings;

use Test::More tests => 12;

use JSON::RPC::LWP;

{
  my $rpc = JSON::RPC::LWP->new( agent => 'lazy' );
  $rpc->agent('new');

  ok !$rpc->has_ua, 'ua attr is lazy';
  is $rpc->ua->agent, $rpc->agent, 'ua->agent set correctly';

  ok !$rpc->has_marshal, 'marshal attr is lazy';
  is $rpc->marshal->user_agent, $rpc->agent, 'marshal->user_agent set correctly';
}

{
  my $rpc = JSON::RPC::LWP->new(
    timeout => 0,
    prefer_get => 0,
    agent => 'lazy',
  );

  ok $rpc->has_ua, 'ua set when something it handles is used';
  is $rpc->ua->agent, $rpc->agent, 'ua->agent set correctly';

  ok $rpc->has_marshal, 'marshal set when something it handles is used';
  is $rpc->marshal->user_agent, $rpc->agent, 'marshal->user_agent set correctly';
}
{
  my $rpc = JSON::RPC::LWP->new( agent => 'lazy' );

  $rpc->timeout(0);
  ok $rpc->has_ua, 'ua set when something it handles is used';
  is $rpc->ua->agent, $rpc->agent, 'ua->agent set correctly';

  $rpc->prefer_get(0);
  ok $rpc->has_marshal, 'marshal set when something it handles is used';
  is $rpc->marshal->user_agent, $rpc->agent, 'marshal->user_agent set correctly';
}

