#!/usr/bin/env perl
use strict;
use warnings;
use JSON::YY ':doc';

# parse JSON into a mutable document
my $doc = jdoc q({
    "users": [
        {"name": "Alice", "age": 30, "role": "admin"},
        {"name": "Bob",   "age": 25, "role": "user"}
    ],
    "meta": {"version": 1}
});

# read values without materializing to Perl
print "type of /users: ",  jtype $doc, "/users",      "\n";  # array
print "user count: ",      jlen  $doc, "/users",      "\n";  # 2
print "first name: ",      jgetp $doc, "/users/0/name", "\n"; # Alice

# modify in-place
jset $doc, "/users/0/age", 31;
jset $doc, "/meta/version", 2;

# add new fields with explicit types
jset $doc, "/meta/active", jbool 1;     # true, not 1
jset $doc, "/meta/id",     jstr "007";  # string, not 7

# append to array
jset $doc, "/users/-", {name => "Carol", age => 28, role => "user"};

# delete
jdel $doc, "/users/1";  # remove Bob

# iterate
my $it = jiter $doc, "/users";
while (defined(my $user = jnext $it)) {
    printf "  %s (age %s)\n", jgetp $user, "/name", jgetp $user, "/age";
}

# clone subtree independently
my $backup = jclone $doc, "/users/0";
jset $backup, "/name", "Alice-backup";
print "backup: ",  jencode $backup, "", "\n";
print "original: ", jencode $doc, "/users/0", "\n";  # unchanged

# serialize
print "\nfull doc:\n", jencode $doc, "", "\n";

# materialize to Perl data
my $perl_data = jgetp $doc, "";
print "\nPerl keys: ", join(", ", sort keys %$perl_data), "\n";
