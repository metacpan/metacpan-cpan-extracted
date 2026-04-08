#!/usr/bin/env perl
# RFC 7386 JSON Merge Patch — declarative partial update
use strict;
use warnings;
use JSON::YY ':doc';

my $doc = jdoc q({
    "title": "My App",
    "database": {"host": "localhost", "port": 5432, "name": "mydb"},
    "features": ["auth", "logging"],
    "debug": true
});

print "before:\n", jpp $doc, "", "\n";

# merge patch: null removes, new keys add, existing keys replace
my $patch = jdoc q({
    "database": {"host": "db.prod.internal", "password": "secret"},
    "debug": null,
    "version": "2.0"
});

jmerge $doc, $patch;
print "after merge:\n", jpp $doc, "", "\n";
# "debug" removed, "database.host" replaced, "database.password" added,
# "version" added, everything else preserved
