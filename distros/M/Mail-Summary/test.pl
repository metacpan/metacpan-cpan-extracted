#!/usr/bin/perl

use strict;
use Test::More tests => 5;
use Mail::Summary;

eval { Mail::Summary->new };
like $@, qr/No args passed to new/, "Can't make with no args";

eval { Mail::Summary->new("wibble") };
like $@, qr/Args to new not a hashref/, "Can't make without a hashref";

eval { Mail::Summary->new({ wobble => "wibble" }) };
like $@, qr/No mail folder given/, 
  "Can't make without a maildir key in hashref";

my $ms = Mail::Summary->new({ maildir => '/home/mwk/Maildir' });
isa_ok $ms, 'Mail::Summary';
is $ms->maildir, '/home/mwk/Maildir', "Correct maildir returned";
