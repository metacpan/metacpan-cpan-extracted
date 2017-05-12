
use strict;
use Test::More tests => 7;

BEGIN { use_ok( 'MIME::Fast' ); }

can_ok('MIME::Fast::Stream', 'read');

pass("module loaded");

#
# Testing message parsing
# ---------------------------------------

# open a file
open(M,"<test.eml") || fail("Can not open test.eml: $!");
pass("file test.eml is opened");

# create a stream
my $str = new MIME::Fast::Stream(\*M);
isa_ok($str, 'MIME::Fast::Stream');

my $buf;
my $bytes = $str->read($buf, 10);

cmp_ok($bytes,'==',10, 'read 10 bytes');
cmp_ok($buf,'eq','Received: ','read into buffer');

undef $str;

