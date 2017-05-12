#!/usr/bin/env perl
#
# RT #69439, insecure /tmp file handling
#

use strict;
use warnings;
use Test::More tests => 11;

use File::Path ();
use HTTP::DAV;

# Dave uses HTTP::DAV::_tempfile() every time
# it has to open a new temporary file

my $tmpdir = ".http-dav-test-tmpdir.$$";

ok(File::Path::mkpath($tmpdir), "Created temp dir");

# Generate two temp files one immediately after the other
my ($fh1, $filename1) = HTTP::DAV::_tempfile('dave', $tmpdir);
my ($fh2, $filename2) = HTTP::DAV::_tempfile('dave', $tmpdir);

ok($fh1);
ok($fh2);
ok($filename1);
ok($filename2);

# They have to have different filenames
isnt($filename1, $filename2, "Different filenames should be generated");
isnt($fh1, $fh2, "They should be different filehandles too, just in case");

#diag("Generated temp file: $filename1");
#diag("Generated temp file: $filename2");

ok(index($filename1, "$tmpdir/dave") > -1);
ok(index($filename2, "$tmpdir/dave") > -1);

is(unlink($filename1, $filename2), 2, "Removed temp files");

ok(File::Path::rmtree($tmpdir), "Cleaned up temp dir");
