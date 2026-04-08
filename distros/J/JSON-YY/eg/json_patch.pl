#!/usr/bin/env perl
# RFC 6902 JSON Patch — atomic operations on a document
use strict;
use warnings;
use JSON::YY ':doc';

my $doc = jdoc q({
    "users": [
        {"name": "Alice", "role": "admin"},
        {"name": "Bob",   "role": "user"}
    ],
    "version": 1
});

print "before:\n", jpp $doc, "", "\n";

# build a patch
my $patch = jdoc q([
    {"op": "test",    "path": "/version",       "value": 1},
    {"op": "replace", "path": "/version",       "value": 2},
    {"op": "add",     "path": "/users/-",       "value": {"name":"Carol","role":"user"}},
    {"op": "remove",  "path": "/users/1"},
    {"op": "move",    "path": "/users/0/email", "from": "/users/0/name"},
    {"op": "copy",    "path": "/backup_version","from": "/version"}
]);

jpatch $doc, $patch;
print "after patch:\n", jpp $doc, "", "\n";
