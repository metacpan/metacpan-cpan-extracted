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

my $audit = Mail::Audit->new(
  data      => $message,
  log       => undef,
  loglevel  => 0,

  accept    => sub { return @_ },
);

my @return = $audit->accept($maildir, { noexit => 1 });

# XXX: In a perfect world, this would work:
# isa_ok($return[0], 'Mail::Audit', 'first arg to custom accept is $self');
# is    ($return[1], $maildir,      'second arg to custom accept is maildir');
# is_deeply($return[2], { noexit => 1 }, 'third arg to custom accept is opts');

is    ($return[0], $maildir,      'second arg to custom accept is maildir');
is_deeply($return[1], { noexit => 1 }, 'third arg to custom accept is opts');
