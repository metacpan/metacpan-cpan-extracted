#!perl
use strict;
use warnings;

use File::Spec ();
use File::Temp ();

use Test::More 'no_plan';

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

my $exit = undef;

my $audit = Mail::Audit->new(
  data      => $message,
  emergency => undef,
  log       => undef,
  loglevel  => 0,

  _exit     => sub { $exit = $_[1] },
);

isa_ok($audit, 'Mail::Audit');

# XXX: use catdir to make this OS-agnostic -- rjbs, 2006-06-01
ok(
  (! -d File::Spec->catdir($maildir, 'new')),
  "the eventual destination isn't a maildir (yet)"
);

{
  $audit->noexit(1);
  $audit->accept($maildir);
  $audit->noexit(0);

  my @files = <$maildir/new/*>;
  is(@files, 1, "we accepted the message to a maildir: 1 message in new/");
  is($exit, undef, "we didn't exit, because noexit was true");
}

{
  $audit->accept($maildir);

  my @files = <$maildir/new/*>;
  is(@files, 2, "we accepted the message to a maildir: 2 messages in new/");
  ok(defined($exit), "we've exited!");
  is($exit, 0, "and the exit code is 0, for delivery");
}

pass("we're still still here! per-method noexit was respected");

