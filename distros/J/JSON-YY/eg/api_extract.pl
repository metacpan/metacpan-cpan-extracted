#!/usr/bin/env perl
# extract specific fields from a large API response without full decode
use strict;
use warnings;
use JSON::YY ':doc';

my $response = q({
    "status": "ok",
    "data": {
        "users": [
            {"id": 1, "name": "Alice", "email": "alice@example.com", "metadata": {"login_count": 42}},
            {"id": 2, "name": "Bob",   "email": "bob@example.com",   "metadata": {"login_count": 7}},
            {"id": 3, "name": "Carol", "email": "carol@example.com", "metadata": {"login_count": 15}}
        ],
        "total": 3,
        "page": 1
    }
});

my $doc = jdoc $response;

# check status without full decode
die "bad status" unless jgetp $doc, "/status" eq "ok";

# extract just what we need
printf "total users: %d\n", jgetp $doc, "/data/total";

# iterate users, extract name + login count
my $it = jiter $doc, "/data/users";
while (defined(my $user = jnext $it)) {
    printf "  %s: %d logins\n",
        jgetp $user, "/name",
        jgetp $user, "/metadata/login_count";
}

# clone just one user for further processing
my $alice = jclone $doc, "/data/users/0";
print "\nalice record: $alice\n";
