BEGIN { $| = 1; print "1..58\n"; }

use utf8;
use JSON::SIMD;
no warnings;

our $test;
sub ok($) {
   print $_[0] ? "" : "not ", "ok ", ++$test, "\n";
}

eval { JSON::SIMD->new->encode ([\-1]) }; ok $@ =~ /cannot encode reference/;
eval { JSON::SIMD->new->encode ([\undef]) }; ok $@ =~ /cannot encode reference/;
eval { JSON::SIMD->new->encode ([\2]) }; ok $@ =~ /cannot encode reference/;
eval { JSON::SIMD->new->encode ([\{}]) }; ok $@ =~ /cannot encode reference/;
eval { JSON::SIMD->new->encode ([\[]]) }; ok $@ =~ /cannot encode reference/;
eval { JSON::SIMD->new->encode ([\\1]) }; ok $@ =~ /cannot encode reference/;

eval { JSON::SIMD->new->use_simdjson(0)->allow_nonref (1)->decode ('"\u1234\udc00"') }; ok $@ =~ /missing high /;
eval { JSON::SIMD->new->use_simdjson(0)->allow_nonref->decode ('"\ud800"') }; ok $@ =~ /missing low /;
eval { JSON::SIMD->new->use_simdjson(0)->allow_nonref (1)->decode ('"\ud800\u1234"') }; ok $@ =~ /surrogate pair /;

eval { JSON::SIMD->new->use_simdjson(0)->allow_nonref (0)->decode ('null') }; ok $@ =~ /allow_nonref/;
eval { JSON::SIMD->new->use_simdjson(0)->allow_nonref (1)->decode ('+0') }; ok $@ =~ /malformed/;
eval { JSON::SIMD->new->use_simdjson(0)->allow_nonref->decode ('.2') }; ok $@ =~ /malformed/;
eval { JSON::SIMD->new->use_simdjson(0)->allow_nonref (1)->decode ('bare') }; ok $@ =~ /malformed/;
eval { JSON::SIMD->new->use_simdjson(0)->allow_nonref->decode ('naughty') }; ok $@ =~ /null/;
eval { JSON::SIMD->new->use_simdjson(0)->allow_nonref (1)->decode ('01') }; ok $@ =~ /leading zero/;
eval { JSON::SIMD->new->use_simdjson(0)->allow_nonref->decode ('00') }; ok $@ =~ /leading zero/;
eval { JSON::SIMD->new->use_simdjson(0)->allow_nonref (1)->decode ('-0.') }; ok $@ =~ /decimal point/;
eval { JSON::SIMD->new->use_simdjson(0)->allow_nonref->decode ('-0e') }; ok $@ =~ /exp sign/;
eval { JSON::SIMD->new->use_simdjson(0)->allow_nonref (1)->decode ('-e+1') }; ok $@ =~ /initial minus/;
eval { JSON::SIMD->new->use_simdjson(0)->allow_nonref->decode ("\"\n\"") }; ok $@ =~ /invalid character/;
eval { JSON::SIMD->new->use_simdjson(0)->allow_nonref (1)->decode ("\"\x01\"") }; ok $@ =~ /invalid character/;
eval { JSON::SIMD->new->use_simdjson(0)->decode ('[5') }; ok $@ =~ /parsing array/;
eval { JSON::SIMD->new->use_simdjson(0)->decode ('{"5"') }; ok $@ =~ /':' expected/;
eval { JSON::SIMD->new->use_simdjson(0)->decode ('{"5":null') }; ok $@ =~ /parsing object/;

eval { JSON::SIMD->new->use_simdjson(0)->decode (undef) }; ok $@ =~ /malformed/;
eval { JSON::SIMD->new->use_simdjson(0)->decode (\5) }; ok !!$@; # Can't coerce readonly
eval { JSON::SIMD->new->use_simdjson(0)->decode ([]) }; ok $@ =~ /malformed/;
eval { JSON::SIMD->new->use_simdjson(0)->decode (\*STDERR) }; ok $@ =~ /malformed/;
eval { JSON::SIMD->new->use_simdjson(0)->decode (*STDERR) }; ok !!$@; # cannot coerce GLOB

eval { decode_json ("\"\xa0") }; ok $@ =~ /UNCLOSED_STRING/;
eval { decode_json ("\"\xa0\"") }; ok $@ =~ /UTF8_ERROR/;
eval { decode_json ("1\x01") }; ok $@ =~ /garbage after/;
eval { decode_json ("1\x00") }; ok $@ =~ /garbage after/;
eval { decode_json ("\"\"\x00") }; ok $@ =~ /garbage after/;
eval { decode_json ("[]\x00") }; ok $@ =~ /garbage after/;

# simdjson decode tests
# unfortunately it doesn't tell us the details about bad surrogates
eval { JSON::SIMD->new->allow_nonref (1)->decode ('"\u1234\udc00"') }; ok $@ =~ /Problem while parsing a string/;
eval { JSON::SIMD->new->allow_nonref->decode ('"\ud800"') }; ok $@ =~ /Problem while parsing a string/;
eval { JSON::SIMD->new->allow_nonref (1)->decode ('"\ud800\u1234"') }; ok $@ =~ /Problem while parsing a string/;

eval { JSON::SIMD->new->allow_nonref (0)->decode ('null') }; ok $@ =~ /allow_nonref/;
eval { JSON::SIMD->new->allow_nonref (1)->decode ('+0') }; ok $@ =~ /improper structure/;
eval { JSON::SIMD->new->allow_nonref->decode ('.2') }; ok $@ =~ /improper structure/;
eval { JSON::SIMD->new->allow_nonref (1)->decode ('bare') }; ok $@ =~ /improper structure/;
eval { JSON::SIMD->new->allow_nonref->decode ('naughty') }; ok $@ =~ /letter 'n'/;
eval { JSON::SIMD->new->allow_nonref (1)->decode ('01') }; ok $@ =~ /leading zero/;
eval { JSON::SIMD->new->allow_nonref->decode ('00') }; ok $@ =~ /leading zero/;
eval { JSON::SIMD->new->allow_nonref (1)->decode ('-0.') }; ok $@ =~ /decimal point/;
eval { JSON::SIMD->new->allow_nonref->decode ('-0e') }; ok $@ =~ /exp sign/;
eval { JSON::SIMD->new->allow_nonref (1)->decode ('-e+1') }; ok $@ =~ /initial minus/;
eval { JSON::SIMD->new->allow_nonref->decode ("\"\n\"") }; ok $@ =~ /unescaped characters/;
eval { JSON::SIMD->new->allow_nonref (1)->decode ("\"\x01\"") }; ok $@ =~ /unescaped characters/;
# doesn't tell us the details
eval { JSON::SIMD->new->decode ('[5') }; ok $@ =~ /JSON document ended early/;
eval { JSON::SIMD->new->decode ('{"5"') }; ok $@ =~ /JSON document ended early/;
eval { JSON::SIMD->new->decode ('{"5":null') }; ok $@ =~ /JSON document ended early/;

eval { JSON::SIMD->new->decode (undef) }; ok $@ =~ /no JSON found/;
eval { JSON::SIMD->new->decode (\5) }; ok !!$@; # Can't coerce readonly
eval { JSON::SIMD->new->decode ([]) }; ok $@ =~ /improper structure/;
eval { JSON::SIMD->new->decode (\*STDERR) }; ok $@ =~ /improper structure/;
eval { JSON::SIMD->new->decode (*STDERR) }; ok !!$@; # cannot coerce GLOB
