#!/usr/bin/perl -w

use lib qw(../blib/lib);
use lib qw(../blib/arch);

use lib qw(blib/lib);
use lib qw(blib/arch);

#use ExtUtils::testlib;

use Data::Dumper;

use IPTables::libiptc;

print "start\n";

my $table = IPTables::libiptc::init('filter');

if (not defined $table) {
    print "\$table undef\n -=-=- STRERR: $!\n";
}
print "after init. Table \"$table\"\n";


#print Dumper($table);

my $success;

my $chainname = "test3";
if( $success = $table->create_chain("$chainname")) {
    print "Create chain: $chainname\n";
} else {
    print "Could NOT create chain: $chainname\n";
}

#$chainname = "aaaaa";
if( $table->is_chain("$chainname")) {
    print "Chain exist: $chainname\n";
} else {
    print "Chain do NOT exist: $chainname\nERR:$!\n";
}

#if( $success = $table->delete_chain("$chainname")) {
#    print "Deleted chain: $chainname\n";
#} else {
#    print "Could NOT delete chain: $chainname\nERR:$!\n";
#}

my $new_name = "test3_renamed";
if( $success = $table->rename_chain("$chainname",$new_name)) {
    print "Renamed chain: $chainname to: $new_name\n";
} else {
    print "Could NOT rename chain: $chainname\nERR:$!\n";
}

if( $table->is_chain("$new_name")) {
    print "Chain exist: $new_name\n";
} else {
    print "Chain do NOT exist: $new_name\nERR:$!\n";
}

if( $table->commit()) {
    print "Commit OK\n";
} else {
    print "Commit FAILED\n";
}
