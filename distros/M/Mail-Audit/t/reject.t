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

    reject    => sub { return $_[0] },
    _exit     => sub { $exit = $_[1] },
  );

  is(
    $audit->reject("everything stinks"),
    "everything stinks",
    "custom-rejected with given reason",
  );
}

{
  my $audit = Mail::Audit->new(
    data      => $message,
    log       => "/dev/null",

    _exit     => sub { $exit = $_[1] },
  );

  undef $exit;

  $audit->reject("everything stinks");
  
  is($exit, 100, "normal reject and we would've exited REJECTED");

  undef $exit;

  $audit->noexit(1);
  $audit->reject("go away");
  $audit->noexit(0);

  is($exit, 100, "normal reject; global noexit ignored");

  undef $exit;

  $audit->reject("bounce!", { noexit => 1 });
  is($exit, 100, "normal reject; local noexit ignored");
}

