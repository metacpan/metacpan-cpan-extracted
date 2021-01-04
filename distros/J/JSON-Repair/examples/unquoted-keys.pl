#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Repair ':all';
print repair_json (
    "{how many roads must a man walk down:42}"
);

