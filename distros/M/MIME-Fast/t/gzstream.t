
use strict;
use Test::More tests => 8;

BEGIN { use_ok( 'MIME::Fast' ); }

can_ok('MIME::Fast::Stream', 'read');

pass("modules loaded");

SKIP: {

eval { require PerlIO::gzip };

skip "PerlIO::gzip not installed", 5 if $@;

#
# Testing message parsing
# ---------------------------------------

# open a file
my $fh;
if (open $fh, "<:gzip", "test.eml.gz") {
  pass("file test.eml.gz is opened");
} else {
  fail("Can not open test.eml.gz: $!");
}    

# create a stream
my $str = new MIME::Fast::Stream($fh);
isa_ok($str, 'MIME::Fast::Stream');

my $buf;
my $bytes = $str->read($buf, 10);

cmp_ok($bytes,'==',10, 'read 10 bytes');
cmp_ok($buf,'eq','Received: ','read into buffer');

if (close($fh)) {
  pass("PerlIO::gzip closed");
} else {
  fail("PerlIO::gzip could not close: $!");
}

undef $str;
}

