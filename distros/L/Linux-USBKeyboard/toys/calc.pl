#!/usr/bin/perl

# Copyright 2008 Eric L. Wilhelm, all rights reserved

# Out-of-band calculator with wx.

use warnings;
use strict;

use Linux::USBKeyboard;

# 1. use|require|system|qx|`|fork|exec|exit => thbbt
# 2. recall up/down?

my @args = @ARGV;
(@args) or
  die 'run `lsusb` to determine your vendor_id, product_id';

my ($vendor, $product) = map({hex($_)}
  $#args ? @args[0,1] : split(/:/, $args[0]));
$product or die "bah";

my $kb = Linux::USBKeyboard->open_keys($vendor, $product);

use File::Basename ();
require(File::Basename::dirname($0) . '/CalcApp.pm');

my $app = CalcApp->new;
my $fr = $app->frame;
my $input = $fr->input;

# setup the fun
my $shown = 1;
my $lock = 1;
my $is = {in => 0};
my @maps = (
  { # nonlock
    #7     => 'home', # TODO - nav
    slash => 'sqrt',
    star  => '(',
    minus => ')',
    dot   => 'del',
  },
  { # numlock
    slash => '/',
    star  => '*',
    dot   => '.',
    plus  => '+',
    minus => '-',
  },
);
$input->SetValue('22890.98034987519807*22222225.6888/1.22255');
Wx::Event::EVT_IDLE($app, sub {
  my ($obj, $evt) = @_;

  $is->{in} and return; # Im in ur idle
  local $is->{in} = 1;

  $kb->blocking(0);
  if(! $kb->eof) {
    $kb->blocking(1);
    chomp(my $k = readline($kb));
    #warn $k, "\n";
    if($k eq 'num_lock') {
      $lock ^= 1;
      $input->SetBackgroundColour($lock ? $fr->green : $fr->red);
    }
    else {
      $k =~ s/^num_//; # XXX this is only the numpad for now
      if(defined(my $key = $maps[$lock]{$k})) {
        $k = $key;
      }
      warn "$k\n";

      if($k eq 'enter') {
        if($lock) {
          my $got = $input->GetValue;
          length($got) or return;
          my $ans = 'thbbt';
          unless($got =~ m/use|require|system|qx|`|fork|exec|exit/) {
            $ans = eval($got);
            if($@) {
              $ans = $@;
            }
          }
          # output
          $fr->add_output($got, $ans);
          $input->SetValue('');

        }
        else { # num_lock+enter => hide/show
          $shown ^= 1;
          $fr->Show($shown);
        }
      }
      else {
        $input->WriteText($k);
      }
    }
  }
  else {
    Wx::Yield();
    use Time::HiRes; Time::HiRes::sleep(0.1);
  }
  Wx::WakeUpIdle();
  #$evt->RequestMore;
});

$app->MainLoop;

# vim:ts=2:sw=2:et:sta
