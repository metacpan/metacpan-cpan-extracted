#!/usr/bin/perl -w
# Test file for Digest::Crc32

use strict;
use Test;
use Digest::Crc32;

BEGIN {plan tests => 2}

my $crc = new Digest::Crc32();
my $cp = $crc->strcrc32("foo");

ok (defined ($crc) and (ref $crc), 'new() is ok');
ok (($cp == 2356372769), '1');


exit;
__END__
