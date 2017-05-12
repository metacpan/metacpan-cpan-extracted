#!/usr/bin/perl -w
use strict;
use Glib qw(TRUE FALSE);
use Gnome2::VFS;

use Test::More;

# $Id$

plan -d "$ENV{ HOME }/.gnome" ?
  (tests => 38) :
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

foreach ([Gnome2::VFS::Directory -> open(TMP, qw(default))],
         [Gnome2::VFS::Directory -> open_from_uri(Gnome2::VFS::URI -> new(TMP), qw(default))]) {
  ($result, $handle) = @{$_};

  is($result, "ok");
  isa_ok($handle, "Gnome2::VFS::Directory::Handle");

  is($handle -> close(), "ok");
}

###############################################################################

my $info;

$handle = Gnome2::VFS::Directory -> open(TMP, qw(default));

($result, $info) = $handle -> read_next();
is($result, "ok");
ok($info -> { name } eq "." || $info -> { name } eq "..");
is($info -> { type }, "directory");

$handle -> close();

###############################################################################

my $callback = sub {
  my ($node, $info, $will_loop) = @_;

  ok(-e TMP . "/" . $node);
  is($info -> { name }, $node);
  ok($will_loop == 0 || $will_loop == 1);

  return (TRUE, FALSE);
};

Gnome2::VFS -> create(TMP . "/bla", "write", TRUE, 0644);
Gnome2::VFS -> create(TMP . "/blu", "write", TRUE, 0644);

is(Gnome2::VFS::Directory -> visit(TMP,
                                   qw(default),
                                   qw(default),
                                   $callback), "ok");

is(Gnome2::VFS::Directory -> visit_uri(Gnome2::VFS::URI -> new(TMP),
                                       qw(default),
                                       qw(default),
                                       $callback), "ok");

is(Gnome2::VFS::Directory -> visit_files(TMP,
                                         [qw(bla blu)],
                                         qw(default),
                                         qw(default),
                                         $callback), "ok");

is(Gnome2::VFS::Directory -> visit_files_at_uri(Gnome2::VFS::URI -> new(TMP),
                                                [qw(bla blu)],
                                                qw(default),
                                                qw(default),
                                                $callback), "ok");

Gnome2::VFS -> unlink(TMP . "/blu");
Gnome2::VFS -> unlink(TMP . "/bla");

###############################################################################

my @infos;

($result, @infos) = Gnome2::VFS::Directory -> list_load(TMP, qw(default));
ok(-e TMP . "/" . $infos[0] -> { name });

###############################################################################

Gnome2::VFS -> shutdown();

###############################################################################

rmdir(TMP) or die("Urgh, couldn't delete the scratch directory: $!\n");
