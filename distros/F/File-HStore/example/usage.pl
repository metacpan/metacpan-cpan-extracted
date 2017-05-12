#!/usr/bin/perl

use File::HStore;

use strict;
use warnings;

my $store = new File::HStore( "/tmp/.teststore", "SHA2" );

### to add a file in the hstore
my $id = $store->add("usage.pl") or die "Unable to add the usage.pl file";
print "usage.pl has been added with the following id in storage : $id\n";

### where is the file in the hstore ?
my $location = $store->getpath("$id");
print "usage.pl is located on the filesystem at the following location : "
    . $location . "\n";

### remove a file from the hstore (based on its id)
$store->remove("$id") or die "Unable to remove usage.pl from the store";

