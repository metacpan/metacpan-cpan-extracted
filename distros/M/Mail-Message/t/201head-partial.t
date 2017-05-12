#!/usr/bin/env perl
#
# Test the removing fields in partial headers.
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Head::Complete;

use Test::More tests => 15;
use IO::Scalar;

my $h = Mail::Message::Head::Complete->build
 ( Subject => 'this is a test'
 , To      => 'you'
 , Top     => 'above'
 , From    => 'me'
 , 'Content-Length' => 12
 , 'Content-Type'   => 'text/plain'
 );  # lines = 6 fields + blank

ok(defined $h);
isa_ok($h, 'Mail::Message::Head::Complete');
isnt(ref($h), 'Mail::Message::Head::Partial');
cmp_ok($h->nrLines, '==', 7);

ok(defined $h->removeFields('to'));
isa_ok($h, 'Mail::Message::Head::Complete');
isa_ok($h, 'Mail::Message::Head::Partial');
cmp_ok($h->nrLines, '==', 6);
ok(defined $h->get('top'));
ok(! defined $h->get('to'));


ok(defined $h->get('Content-Length'));
ok(defined $h->removeFields( qr/^Content-/i ));
isa_ok($h, 'Mail::Message::Head::Partial');
cmp_ok($h->nrLines, '==', 4);
ok(!defined $h->get('Content-Length'));
