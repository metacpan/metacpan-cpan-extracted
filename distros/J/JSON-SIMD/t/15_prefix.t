BEGIN { $| = 1; print "1..4\n"; }

use JSON::SIMD;

my $xs = JSON::SIMD->new->latin1->allow_nonref;

eval { $xs->decode ("[] ") };
print $@ ? "not " : "", "ok 1\n";
eval { $xs->decode ("[] x") };
print $@ ? "" : "not ", "ok 2\n";
print 2 == ($xs->decode_prefix ("[][]"))[1] ? "" : "not ", "ok 3\n";
print 4 == ($xs->decode_prefix ("[1] t"))[1] ? "" : "not ", "ok 4\n"; # simdjson gobbles up trailing whitespace

