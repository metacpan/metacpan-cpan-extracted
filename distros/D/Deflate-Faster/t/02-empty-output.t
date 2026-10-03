# Test uncompressing data which uncompresses to an empty string.

use warnings;
use strict;
use Test::More;
use Deflate::Faster ':all';

my $empty_gzip = "\x1f\x8b\x08\x00\x00\x00\x00\x00\x00\x03\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00";
my $empty_zlib = "\x78\x9c\x03\x00\x00\x00\x00\x01";

is (gunzip ($empty_gzip), '', "gunzip of an empty member");
is (inflate ($empty_zlib), '', "inflate of an empty stream");

my $df = Deflate::Faster->new ();
is ($df->unzip (gzip ('previous output')), 'previous output', "unzip");
is ($df->unzip ($empty_gzip), '', "unzip of an empty member after other output");

done_testing ();
