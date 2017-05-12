#!/usr/bin/perl

# Copyright (C) 2009 Eric L. Wilhelm, All Rights Reserved.

# This example uses Audio::XMMSClient to implement 'previous', 'next',
# and 'play/pause' functions on a numpad's '0', '.', and 'Enter' keys.

use warnings;
use strict;

use Linux::USBKeyboard;

my @args = @ARGV;

(@args) or
  die 'run `lsusb` to determine your vendor_id, product_id';


my ($vendor, $product) = map({hex($_)}
  $#args ? @args[0,1] : split(/:/, $args[0]));
$product or die "bah";

my $kb = Linux::USBKeyboard->open_keys($vendor, $product);

require Audio::XMMSClient;
my $client = Audio::XMMSClient->new('knob');
$client->connect or die "failed to connect to xmms";
my $X = sub {
  my $n = shift;
  my $res = $client->$n(@_);
  $res->wait;
  die $res->get_error if($res->iserror);
  $res->value;
};
my $current = sub {
  my $list = $X->(playlist_list =>);
  my $now  = $X->(playback_current_id =>);
  my ($p, $what) = grep({$list->[$_] == $now} 0..$#$list);
  return($p, $#$list);
};
my $tickle = sub { # tickle harder
  $X->('playback_tickle');
  my $s = $X->(playback_status =>);
  $X->(playback_start=>) unless($s == 1);
};
my %on = (
  num_0     => sub {
    my ($c, $max) = $current->();
    $X->(playlist_set_next => ($c == 0 ? $max : $c - 1));
    $tickle->();
  },
  num_dot => sub {
    my ($c, $max) = $current->();
    $X->(playlist_set_next => ($c == $max ? 0 : $c + 1));
    $tickle->();
  },
  num_enter   => sub {
    my $s = $X->(playback_status =>);
    $s = 0 if($s == 2); # paused
    $X->($s ? 'playback_pause' : 'playback_start');
  },
);

while(my $key = <$kb>) {
  chomp($key);
  if(my $cb = $on{$key}) {
    $cb->();
  }
  else {
    warn "nothing on $key\n";
  }
}

# vim:ts=2:sw=2:et:sta
