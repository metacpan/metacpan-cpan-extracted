BEGIN { $| = 1; print "1..22\n"; }
BEGIN { $^W = 0 } # hate

use JSON::SIMD;

$json = JSON::SIMD->new->convert_blessed->allow_tags->allow_nonref;

print "ok 1\n";

sub JSON::SIMD::tojson::TO_JSON {
   print @_ == 1 ? "" : "not ", "ok 3\n";
   print JSON::SIMD::tojson:: eq ref $_[0] ? "" : "not ", "ok 4\n";
   print $_[0]{k} == 1 ? "" : "not ", "ok 5\n";
   7
}

$obj = bless { k => 1 }, JSON::SIMD::tojson::;

print "ok 2\n";

$enc = $json->encode ($obj);
print $enc eq 7 ? "" : "not ", "ok 6 # $enc\n";

print "ok 7\n";

sub JSON::SIMD::freeze::FREEZE {
   print @_ == 2 ? "" : "not ", "ok 8\n";
   print $_[1] eq "JSON" ? "" : "not ", "ok 9\n";
   print JSON::SIMD::freeze:: eq ref $_[0] ? "" : "not ", "ok 10\n";
   print $_[0]{k} == 1 ? "" : "not ", "ok 11\n";
   (3, 1, 2)
}

sub JSON::SIMD::freeze::THAW {
   print @_ == 5 ? "" : "not ", "ok 13\n";
   print JSON::SIMD::freeze:: eq $_[0] ? "" : "not ", "ok 14\n";
   print $_[1] eq "JSON" ? "" : "not ", "ok 15\n";
   print $_[2] == 3 ? "" : "not ", "ok 16\n";
   print $_[3] == 1 ? "" : "not ", "ok 17\n";
   print $_[4] == 2 ? "" : "not ", "ok 18\n";
   777
}

$obj = bless { k => 1 }, JSON::SIMD::freeze::;
$enc = $json->encode ($obj);
print $enc eq '("JSON::SIMD::freeze")[3,1,2]' ? "" : "not ", "ok 12 # $enc\n";

$dec = $json->decode ($enc);
print $dec eq 777 ? "" : "not ", "ok 19\n";

print $json->get_use_simdjson == 0 ? "" : "not ", "ok 20\n";
$json = JSON::SIMD->new->allow_tags->use_simdjson(1);
print $json->get_use_simdjson == 0 ? "" : "not ", "ok 21\n";

print "ok 22\n";

