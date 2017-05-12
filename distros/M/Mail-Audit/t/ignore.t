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

my $exit = undef;

{
  my $audit = Mail::Audit->new(
    data      => $message,
    log       => "/dev/null",

    ignore    => sub { return @_ },
    _exit     => sub { $exit = $_[1] },
  );

  $audit->ignore;
  
  ok(1, "we can ignore a mail and the world doesn't end");
  is($exit, 0, "and we would've exited ok");

  undef $exit;

  $audit->noexit(1);
  $audit->ignore;
  $audit->noexit(0);

  ok(1, "another message ignored");
  is($exit, undef, "and we wouldn't exit because of global noexit");

  undef $exit;

  $audit->ignore({ noexit => 1 });

  ok(1, "another dropped and the world just shrugs it off");
  is($exit, undef, "and we wouldn't exit because of local noexit");
}

