#!/usr/bin/perl -w

use strict;

use Test::More tests => 6;

BEGIN {
  use_ok('Mail::Qmail::Queue::Receive::Body');
};

our $rb;

sub new_test_object
{
  open(ENVIN,"< t/21RecvBody.in")
      or die "Couldn't open t/21RecvBody.in: $!\n";
  $rb = Mail::Qmail::Queue::Receive::Body->new(FileHandle => \*ENVIN)
      or die "Couldn't create Mail::Qmail::Queue::Receive::Body object: $!\n";
}

new_test_object();
is("This is a test message\nwith 2 lines.\n",$rb->body);

new_test_object();
my $fh = $rb->body_fh()
  or die "Couldnt' get body filehandle: $!\n";
is("This is a test message\n",<$fh>);
is("with 2 lines.\n",<$fh>);
is(undef,<$fh>);
ok($rb->close());

