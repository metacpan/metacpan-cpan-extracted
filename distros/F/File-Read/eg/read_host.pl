#!/usr/bin/perl
use strict;
use Data::Dumper;
use File::Read;

# read /etc/hosts and put the the contents in a hash which gives the IP 
# address of the hostnames, thus providing an el-Cheapo resolving thingy :)

my %addr = map { my ($ip,@names) = split /\s+/; map { $_ => $ip } @names } 
    read_file({ aggregate => 0, skip_blanks => 1, skip_comments => 1 }, '/etc/hosts');

print Dumper(\%addr);
