#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw(no_plan);

use File::Fu;

{ # invalid ops
  my $f = File::Fu->dir;

  eval {my $nope = $f - 8};
  like($@, qr/^- is not a valid op/);

  eval {my $nope = $f * 8};
  like($@, qr/^\* is not a valid op/);

  eval {my $nope = $f << 8};
  like($@, qr/^<< is not a valid op/);
}

{ # readlink on a non-link
  my $f = File::Fu->file("blortleblat89");
  $f->e and $f->unlink;
  ok(! $f->e, "no $f") or die "where did $f come from?!";
  eval {my $l = $f->readlink};
  like($@, qr/^cannot readlink .* No such/, 'no readlink on nil');
  my $fh = $f->open('>');
  close($fh) or die "ack $!";
  eval {my $l = $f->readlink};
  like($@, qr/^cannot readlink .* Invalid/, 'no readlink on file');
  $f->unlink;
}

# vim:ts=2:sw=2:et:sta
