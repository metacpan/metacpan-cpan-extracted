#!/usr/bin/env perl
# read a JSON config file, modify specific values, write back
use strict;
use warnings;
use JSON::YY ':doc';

my $json = q({
    "database": {
        "host": "localhost",
        "port": 5432,
        "name": "myapp"
    },
    "cache": {
        "enabled": false,
        "ttl": 300
    },
    "features": ["auth", "logging"]
});

my $config = jdoc $json;

# modify specific fields
jset $config, "/database/host", "db.prod.internal";
jset $config, "/database/port", 5433;
jset $config, "/cache/enabled", jbool 1;
jset $config, "/cache/ttl", 600;

# add a new feature
jset $config, "/features/-", "metrics";

# add a new section
jset $config, "/redis", jfrom {host => "redis.local", port => 6379};

# write back (pretty-printed via yyjson OO for readability)
print jencode $config, "", "\n";
