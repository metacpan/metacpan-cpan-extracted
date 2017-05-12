#!/usr/bin/perl -w

use lib qw(../blib/lib);
use lib qw(../blib/arch);

use lib qw(blib/lib);
use lib qw(blib/arch);

#use ExtUtils::testlib;

use Data::Dumper;

use IPTables::libiptc;

print "start\n";

$table_name = 'filter';
my $table = IPTables::libiptc::init("$table_name");

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

$chainname = "test";
if( $success = $table->create_chain("$chainname")) {
    print "Chain $chainname is created\n";
} else {
    print "Chain $chainname is NOT created\n";
}


#@arguments = ("-t", "filter", "-A", "INPUT");
#@arguments = ("-A", "INPUT", "-s", "1.2.3.4");
#@arguments = ("-N", "test");
#@arguments = ("-N", "test");
#@arguments = ("-A test", "-p", "tcp");
#@arguments = ("-I", "test", "-s", "4.3.2.1");
@arguments = ("-I", "test", "-s", "4.3.2.1", "-j", "ACCEPT");
#@arguments = ("-t", "filter", "-N test");
#@arguments = ("-h");
#@arguments = ("--help");
#@arguments = ["--help", "-m tcp"];
print Dumper(\@arguments);

if( $success = $table->iptables_do_command(\@arguments)) {
    print "do_command ok: $success\n ERR:$!\n";
} else {
    print "do_command failed: $success\n ERR:$!\n";
}




if( $table->commit()) {
    print "Commit OK\n";
} else {
    print "Commit FAILED\n";
}
