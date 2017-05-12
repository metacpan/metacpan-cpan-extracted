#!/usr/bin/perl
use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Test::More tests => 14;

# $Id$

use GStreamer -init;

my $bus = GStreamer::Bus -> new();
isa_ok($bus, "GStreamer::Bus");

my $src = GStreamer::Bin -> new("urgs");
my $message = GStreamer::Message::EOS -> new($src);

ok($bus -> post($message));
ok($bus -> have_pending());

isa_ok($bus -> peek(), "GStreamer::Message");
isa_ok($bus -> pop(), "GStreamer::Message");

is($bus -> peek(), undef);
is($bus -> pop(), undef);

$bus -> set_flushing(FALSE);

is($bus -> poll("any", 0), undef);

$bus -> add_signal_watch();
$bus -> remove_signal_watch();

my $loop = Glib::MainLoop -> new();

Glib::Idle -> add(sub { $bus -> post($message); $bus -> post($message); FALSE; });
my $id = $bus -> add_watch(sub {
  my ($bussy, $messy, $data) = @_;
  my $i = 0 if 0;

  is($bussy, $bus);
  isa_ok($messy, "GStreamer::Message::EOS");
  is($data, "bla");

  $loop -> quit() if $i++;

  TRUE;
}, "bla");

$loop -> run();

Glib::Source -> remove($id);
