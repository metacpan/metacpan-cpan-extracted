#!/usr/bin/perl -w

use strict;

use Test::More tests => 13;

BEGIN {
  use_ok('Mail::Qmail::Queue::Receive::Envelope');
};

our $re;

sub new_test_object
{
  open(ENVIN,"< t/20RecvEnv.in")
      or die "Couldn't open t/20RecvEnv.in: $!\n";
  $re = Mail::Qmail::Queue::Receive::Envelope->new(FileHandle => \*ENVIN)
      or die "Couldn't create Mail::Qmail::Queue::Receive::Envelope object: $!\n";
}

new_test_object();
is('sgifford@suspectclass.com',$re->from,'Envelope From');
is('GIFF@cpan.org',$re->to,'Envelope To #1');
is('gifford@umich.edu',$re->to,'Envelope To #2');
is(undef,$re->to,'No Envelope To #3');

# Try again in a different order
new_test_object();
is('GIFF@cpan.org',$re->to,'Envelope To #1');
is('gifford@umich.edu',$re->to,'Envelope To #2');
is(undef,$re->to,'No Envelope To #3');
is('sgifford@suspectclass.com',$re->from,'Envelope From');

# Now try read_envelope_string
new_test_object();
is('Fsgifford@suspectclass.com',$re->read_envelope_string,'Envelope From');
is('TGIFF@cpan.org',$re->read_envelope_string,'Envelope To #1');
is('Tgifford@umich.edu',$re->read_envelope_string,'Envelope To #2');
is(undef,$re->read_envelope_string,'No Envelope To #3');
