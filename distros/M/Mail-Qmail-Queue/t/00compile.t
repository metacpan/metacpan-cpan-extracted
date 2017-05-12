#!/usr/bin/perl -w

use strict;

use Test::More tests => 5;

BEGIN { 
  use_ok('Mail::Qmail::Queue::Error');
  use_ok('Mail::Qmail::Queue::Receive::Envelope');
  use_ok('Mail::Qmail::Queue::Receive::Body');
  use_ok('Mail::Qmail::Queue::Send');
  use_ok('Mail::Qmail::Queue::Message');
};
