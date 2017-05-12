#!/usr/bin/perl -w
use strict;
use Gnome2::VFS;

use Test::More;

# $Id$

plan -d "$ENV{ HOME }/.gnome" ?
  (tests => 48) :
  (skip_all => "You have no ~/.gnome");

Gnome2::VFS -> init();

###############################################################################

use Cwd qw(cwd);
use constant TMP => cwd() . "/tmp";

unless (-e TMP) {
  mkdir(TMP) or die ("Urgh, couldn't create the scratch directory: $!");
}

###############################################################################

my ($result, $handle);

foreach ([Gnome2::VFS -> open(cwd() . "/" . $0, "read")],
         [Gnome2::VFS::URI -> new(cwd() . "/" . $0) -> open("read")],
         [Gnome2::VFS -> create(TMP . "/blaaaaaaaaa", "write", 1, 0777)],
         [Gnome2::VFS::URI -> new(TMP . "/bleeeeeeeee") -> create("write", 1, 0666)]) {
  ($result, $handle) = @{$_};

  is($result, "ok");
  isa_ok($handle, "Gnome2::VFS::Handle");

  is($handle -> close(), "ok");
}

###############################################################################

is(Gnome2::VFS -> move(TMP . "/blaaaaaaaaa", TMP . "/bla", 0), "ok");
is(Gnome2::VFS::URI -> new(TMP . "/bleeeeeeeee") -> move(Gnome2::VFS::URI -> new(TMP . "/ble"), 0), "ok");

is_deeply([Gnome2::VFS -> check_same_fs(TMP . "/bla", TMP . "/ble")], ["ok", 1]);
is_deeply([Gnome2::VFS::URI -> new(TMP . "/bla") -> check_same_fs(Gnome2::VFS::URI -> new(TMP . "/ble"))], ["ok", 1]);

is(Gnome2::VFS -> create_symbolic_link(Gnome2::VFS::URI -> new(TMP . "/bli"), "/usr/bin/perl"), "ok");

is(Gnome2::VFS -> set_file_info(TMP . "/bla",
                                { permissions => [qw/user-read user-write/] },
                                qw/permissions/), "ok");

is(Gnome2::VFS -> unlink(TMP . "/bla"), "ok");
is(Gnome2::VFS -> unlink(TMP . "/bli"), "ok");

my $uri = Gnome2::VFS::URI -> new(TMP . "/ble");

is($uri -> set_file_info({ permissions => [qw/user-read user-write/] },
                         qw/permissions/), "ok");

ok($uri -> exists());
is($uri -> unlink(), "ok");

###############################################################################

($result, $handle) = Gnome2::VFS -> create(TMP . "/blu", "write", 1, 0644);
is($result, "ok");
is_deeply([$handle -> write("blaaa!", 6)], ["ok", 6]);

($result, $handle) = Gnome2::VFS -> open(TMP . "/blu", "read");
is($result, "ok");
is_deeply([$handle -> read(6)], ["ok", 6, "blaaa!"]);

is_deeply([$handle -> tell()], ["ok", 6]);

is($handle -> seek("start", 2), "ok");
is_deeply([$handle -> read(4)], ["ok", 4, "aaa!"]);

is($handle -> truncate(0), "error-not-supported");

SKIP: {
  skip "forget_cache is new in 2.12", 1
    unless Gnome2::VFS -> CHECK_VERSION(2, 12, 0);

  is($handle -> forget_cache(0, 0), "ok");
}

is($handle -> close(), "ok");

###############################################################################

is(Gnome2::VFS -> truncate(TMP . "/blu", 5), "ok");
is(Gnome2::VFS::URI -> new(TMP . "/blu") -> truncate(4), "ok");

($result, $handle) = Gnome2::VFS -> open(TMP . "/blu", [qw(read write random)]);
is($result, "ok");

my $info;

($result, $info) = Gnome2::VFS -> get_file_info(TMP . "/blu", qw(default));
is($result, "ok");
is($info -> { size }, 4);

($result, $info) = Gnome2::VFS::URI -> new(TMP . "/blu") -> get_file_info(qw(get-mime-type));
is($result, "ok");
ok(defined($info -> { mime_type }));

($result, $info) = $handle -> get_file_info(qw(default));
is($result, "ok");
isa_ok($info -> { permissions }, "Gnome2::VFS::FilePermissions");

is($handle -> close(), "ok");

is(Gnome2::VFS -> unlink(TMP . "/blu"), "ok");

###############################################################################

# FIXME: any way to reliably test this?  (currently needs FAM and some luck.)
# my $monitor;

# ($result, $monitor) = Gnome2::VFS::Monitor -> add(TMP, qw(directory), sub {
#   my ($handle, $monitor_uri, $info_uri, $event_type) = @_;

#   isa_ok($handle, "Gnome2::VFS::Monitor::Handle");
#   is($monitor_uri, "file://" . TMP);
#   is($info_uri, "file://" . TMP . "/ulb");
#   ok($event_type eq "created" or $event_type eq "deleted");
# });

# is($result, "ok");
# isa_ok($monitor, "Gnome2::VFS::Monitor::Handle");

###############################################################################

is(Gnome2::VFS -> make_directory(TMP . "/ulb", 0755), "ok");
is(Gnome2::VFS -> remove_directory(TMP . "/ulb"), "ok");

$uri = Gnome2::VFS::URI -> new(TMP . "/ulb");

is($uri -> make_directory(0755), "ok");
is($uri -> remove_directory(), "ok");

###############################################################################

# shortly enter the main loop so that the monitor receives the events.
# Glib::Idle -> add(sub {
#   Gtk2 -> main_quit();
#   return 0;
# });

# use Gtk2 -init;
# Gtk2 -> main();

# is($monitor -> cancel(), "ok");

###############################################################################

Gnome2::VFS -> shutdown();

###############################################################################

rmdir(TMP) or die("Urgh, couldn't delete the scratch directory: $!\n");
