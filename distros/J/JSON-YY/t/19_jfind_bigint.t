use strict; use warnings;
use Test::More;
use JSON::YY ':doc';

# Regression: jfind compares integer fields as 64-bit integers, not doubles,
# so values above 2^53 don't collide via floating-point rounding.
# NB: the Doc keywords are list operators — call them without parentheses.

# 2^53 vs 2^53+1 (indistinguishable as doubles)
{
    my $doc = jdoc '[{"id":9007199254740992,"n":"lo"},{"id":9007199254740993,"n":"hi"}]';
    my $lo = jfind $doc, "", "/id", 9007199254740992;
    my $hi = jfind $doc, "", "/id", 9007199254740993;
    my $lon = jgetp $lo, "/n";
    my $hin = jgetp $hi, "/n";
    is $lon, "lo", 'jfind matches exact 2^53';
    is $hin, "hi", 'jfind matches exact 2^53+1 (no double collision)';
}

# unsigned 64-bit beyond 2^63
{
    my $doc = jdoc '[{"id":18446744073709551610},{"id":18446744073709551615}]';
    my $hit  = jfind $doc, "", "/id", 18446744073709551615;
    my $miss = jfind $doc, "", "/id", 18446744073709551611;
    ok  defined $hit,  'jfind matches UINT64_MAX';
    ok !defined $miss, 'jfind does not match a near-miss uint64 (would collide as double)';
}

# negative sint beyond -2^53
{
    my $doc = jdoc '[{"v":-5},{"v":-9007199254740993}]';
    my $hit = jfind $doc, "", "/v", -9007199254740993;
    ok defined $hit, 'jfind matches large negative integer';
}

# real-valued fields still compared as doubles
{
    my $doc = jdoc '[{"p":3.14},{"p":2.71}]';
    my $hit = jfind $doc, "", "/p", 2.71;
    ok defined $hit, 'jfind still matches real values';
}

# small integers and string matches unaffected
{
    my $doc = jdoc '[{"id":1,"k":"a"},{"id":2,"k":"b"}]';
    my $byid  = jfind $doc, "", "/id", 2;
    my $bystr = jfind $doc, "", "/k", "a";
    my $k  = jgetp $byid,  "/k";
    my $id = jgetp $bystr, "/id";
    is $k,  "b", 'jfind small int';
    is $id, 1,   'jfind string match';
}

# null-field matching (the string "null" matches a JSON null field)
{
    my $doc = jdoc '[{"id":1,"s":null},{"id":2,"s":"x"}]';
    my $hit = jfind $doc, "", "/s", "null";
    my $id  = jgetp $hit, "/id";
    is $id, 1, 'jfind matches a JSON null field';
}

done_testing;
