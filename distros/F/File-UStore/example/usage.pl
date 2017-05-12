#!/usr/bin/perl

use File::UStore;

use strict;
use warnings;

my $store = new File::UStore( path => "/tmp/.teststore", 
                              prefix => "prefix_",
                              depth  => 5
                            );

### to add a file in the store
open( my $file, "usage.pl" ) or die "Unable to open file ";
my $id = $store->add(*$file) or die "Unable to add the usage.pl file";
close $file;
print "usage.pl has been added with the following id in storage : $id\n";

### Returns the file handle for the file represented by the id. (This might not work if your storage and access scheme is too wierd.)
my $FH = $store->get("$id");

print <$FH>;

### where is the file in the store ?
my $location = $store->getpath("$id");
print "usage.pl is located on the filesystem at the following location : "
    . $location . "\n";

### remove a file from the store (based on its id)
$store->remove("$id") or die "Unable to remove usage.pl from the store";

