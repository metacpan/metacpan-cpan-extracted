#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use t::Test;
use Diff::LibXDiff;

my ($patched, $rejected, $string1, $string2);
my ($bdiff, $file1, $file2,$filediff, $bpatched);

($patched, $rejected) = Diff::LibXDiff->patch( 'A', <<'_END_' );
@@ -1,1 +1,1 @@
-A
\ No newline at end of file
+b
\ No newline at end of file
_END_
is( $patched, 'b' );

$string1 = <<_END_;
apple
banana
cherry
_END_

$string2 = <<_END_;
apple
grape
cherry
lime
_END_

($patched, $rejected) = Diff::LibXDiff->patch( $string1, <<'_END_' );
@@ -1,3 +1,4 @@
 apple
-banana
+grape
 cherry
+lime
_END_
is( $patched, $string2 );

SKIP: {
    my $base64 = t::Test->base64;
    skip "Missing or restricted $base64" unless -x $base64;
    my %data = t::Test->data;

    my $binary2 = Diff::LibXDiff->bpatch( $data{binary1}, $data{binarydiff} );
    is( $binary2, $data{binary2} );
}
