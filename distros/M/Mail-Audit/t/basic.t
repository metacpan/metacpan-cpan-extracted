#!perl
use strict;
use warnings;

use File::Spec ();
use File::Temp ();

use Test::More tests => 10;

BEGIN { use_ok('Mail::Audit'); }

sub readfile {
  my ($name) = @_;
  local *MESSAGE_FILE;
  open MESSAGE_FILE, "<$name" or die "coudn't read $name: $!";
  my @lines = <MESSAGE_FILE>;
  close MESSAGE_FILE;
  return \@lines;
}

my $message = readfile('t/messages/simple.msg');

my $maildir   = File::Temp::tempdir(CLEANUP => 1);
my $emergency = File::Temp::tempdir(CLEANUP => 1);

# $faildir will be a directory name that would exist beneath a file, so it will
# not be create-able; thanks to HDP for this idea, which replaces the previous
# implementation, a directory chmod'ed 0000, which failed when the user was
# root
my (undef, $failfile) = File::Temp::tempfile(UNLINK => 1);
my $faildir = File::Spec->catdir($failfile, 'Maildir');

my $logdir    = File::Temp::tempdir(CLEANUP => 1);

my $audit = Mail::Audit->new(
  data      => $message,
  emergency => $emergency,
  log       => "$logdir/log",
  loglevel  => 0,
);

isa_ok($audit, 'Mail::Audit');

ok(
  (! -d File::Spec->catdir($emergency, 'new')),
  "emergency dir isn't a maildir before any accepts"
);

ok(
  (! -d File::Spec->catdir($maildir, 'new')),
  "and neither is the other temporary dir"
);

$audit->noexit(1);
$audit->accept($maildir);
$audit->noexit(0);

pass("we're still here! object-wide noexit was respected");

ok(
  (! -d File::Spec->catdir($emergency, 'new')),
  "emergency dir isn't a maildir after first accept"
);

ok(
  (  -d File::Spec->catdir($maildir, 'new')),
  "but the other maildir, which we accepted, is"
);

$audit->accept($faildir, { noexit => 1 });
ok(
  (  -d File::Spec->catdir($emergency, 'new')),
  "after accept to impossible destination, emergency is maildir"
);

pass("we're still still here! per-method noexit was respected");

ok((  -f "$logdir/log"),    "a log was created");
