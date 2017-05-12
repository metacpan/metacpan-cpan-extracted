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
    print "\$table is undef\n -=-=- STRERR: $!\n";
}
print "after init. Table \"$table\"\n";


#print Dumper($table);

my $success;

#my $chainname = "FORWARD";
my $chainname = "INPUT";
if( $success = $table->builtin("$chainname")) {
    print "Chain is buildin: $chainname\n";
} else {
    print "Chain is NOT buildin: $chainname\n";
}

#$chainname = "aaaaa";
if( $table->is_chain("$chainname")) {
    print "Chain exist: $chainname\n";
} else {
    print "Chain do NOT exist: $chainname\n ERR:$!\n";
}

my $retval;
my ($pkt_cnt, $byte_cnt) = (42, 666);
my $policy = "ACCEPT";
#if( $table->set_policy("$chainname", "$policy", $pkt_cnt, $byte_cnt)) {
#if( my ($old_policy, $old_pkt_cnt, $old_byte_cnt) = $table->set_policy("$chainname", "$policy")) {

($retval, $old_policy, $old_pkt_cnt, $old_byte_cnt) = 
    $table->set_policy("$chainname", "$policy", $pkt_cnt, $byte_cnt);

if( $retval ) {
    print "SETing chain $chainname policy: $policy\n";
    print "(NEW pkts:$pkt_cnt bytes:$byte_cnt)\n";
    print "(OLD policy:$old_policy pkts:$old_pkt_cnt bytes:$old_byte_cnt)\n";
} else {
    print "Chain $chainname cannot set policy\n ERR:$!\n";
}

if( ($policy, $pkt_cnt, $byte_cnt) = $table->get_policy("$chainname")) {
#if( my ($policy) = $table->get_policy("$chainname")) {
    print "Chain $chainname policy: $policy (pkts:$pkt_cnt bytes:$byte_cnt)\n";
} else {
    print "Chain $chainname cannot get policy\n ERR:$!\n";
}

$policy="ACCEPT";
if( $table->set_policy("$chainname", "$policy") ) {
    print "[2]SETing chain $chainname policy: $policy\n";
} else {
    print "[2]Chain $chainname cannot set policy\n ERR:$!\n";
}

if( ($policy, $pkt_cnt, $byte_cnt) = $table->get_policy("$chainname")) {
#if( my ($policy) = $table->get_policy("$chainname")) {
    print "GET Chain $chainname policy: $policy (pkts:$pkt_cnt bytes:$byte_cnt)\n";
} else {
    print "GET Chain $chainname cannot get policy\n ERR:$!\n";
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
    print "Could NOT rename chain: $chainname\n ERR:$!\n";
}

if( $table->is_chain("$new_name")) {
    print "Chain exist: $new_name\n";
} else {
    print "Chain do NOT exist: $new_name\n ERR:$!\n";
}

$new_name="slet1_jump";
my $refs;
if( ($refs = $table->get_references("$new_name")) >= 0) {
    print "Chain $new_name references: $refs\n";
} else {
    print "Chain $new_name: get_references failed\n ERR:$!\n";
}


if( $table->commit()) {
    print "Commit OK\n";
} else {
    print "Commit FAILED\n";
}
