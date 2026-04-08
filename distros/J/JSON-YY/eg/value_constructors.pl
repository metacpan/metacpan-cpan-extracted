#!/usr/bin/env perl
use strict;
use warnings;
use JSON::YY ':doc';

# value constructors create typed JSON values as Doc handles
my $doc = jdoc '{}';

jset $doc, "/str",   jstr "007";     # "007" not 7
jset $doc, "/num",   jnum 42;        # 42
jset $doc, "/pi",    jnum 3.14;      # 3.14
jset $doc, "/yes",   jbool 1;        # true
jset $doc, "/no",    jbool 0;        # false
jset $doc, "/empty", jnull;          # null
jset $doc, "/list",  jarr;           # []
jset $doc, "/map",   jobj;           # {}

print jencode $doc, "", "\n";
# {"str":"007","num":42,"pi":3.14,"yes":true,"no":false,"empty":null,"list":[],"map":{}}

# populate the empty containers
jset $doc, "/list/-", 1;
jset $doc, "/list/-", 2;
jset $doc, "/map/key", "value";

print jencode $doc, "/list", "\n";   # [1,2]
print jencode $doc, "/map", "\n";    # {"key":"value"}
