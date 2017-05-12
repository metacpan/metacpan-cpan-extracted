#!/usr/bin/perl -w
use strict;
use Gnome2::VFS;

use Test::More;

# $Id$

plan -d "$ENV{ HOME }/.gnome" ?
  (tests => 11) :
  (skip_all => "You have no ~/.gnome");

Gnome2::VFS -> init();

###############################################################################

use Cwd qw(cwd);
use constant TMP => cwd() . "/tmp";

unless (-e TMP) {
  mkdir(TMP) or die ("Urgh, couldn't create the scratch directory: $!");
}

###############################################################################

my $progress = sub {
  my ($info) = @_;

  my $done_that = 0 if 0;
  isa_ok($info, "HASH") unless $done_that++;

  if ($info -> { status } eq "ok") {
    return 1;
  }
  elsif ($info -> { status } eq "vfserror") {
    return "abort";
  }
  elsif ($info -> { status } eq "overwrite") {
    return "replace";
  }

  return 0;
};

###############################################################################

foreach (qw(a e i o)) {
  my $handle = Gnome2::VFS -> create(TMP . "/bl" . $_, "write", 1, 0644);
  $handle -> write("blaaa!", 6);
  $handle -> close();
}

###############################################################################

my $source = Gnome2::VFS::URI -> new("file://" . TMP . "/bla");
my $destination = Gnome2::VFS::URI -> new("file://" . TMP . "/blaa");

is(Gnome2::VFS::Xfer -> uri($source,
                            $destination,
                            qw(default),
                            qw(query),
                            qw(query),
                            $progress), "ok");

ok(-e $destination -> to_string(qw(toplevel-method)));

is($source -> unlink(), "ok");
is($destination -> unlink(), "ok");

###############################################################################

my @source = (Gnome2::VFS::URI -> new("file://" . TMP . "/ble"),
              Gnome2::VFS::URI -> new("file://" . TMP . "/bli"),
              Gnome2::VFS::URI -> new("file://" . TMP . "/blo"));

my @destination = (Gnome2::VFS::URI -> new("file://" . TMP . "/blee"),
                   Gnome2::VFS::URI -> new("file://" . TMP . "/blii"),
                   Gnome2::VFS::URI -> new("file://" . TMP . "/bloo"));

is(Gnome2::VFS::Xfer -> uri_list(\@source,
                                 \@destination,
                                 qw(default),
                                 qw(query),
                                 qw(query),
                                 $progress), "ok");

foreach (@destination) {
  ok(-e $_ -> to_string(qw(toplevel-method)));
}

is(Gnome2::VFS::Xfer -> delete_list(\@source,
                                    qw(query),
                                    qw(default),
                                    $progress), "ok");

is(Gnome2::VFS::Xfer -> delete_list(\@destination,
                                    qw(query),
                                    qw(default),
                                    $progress), "ok");

###############################################################################

Gnome2::VFS -> shutdown();

###############################################################################

rmdir(TMP) or die("Urgh, couldn't delete the scratch directory: $!\n");
