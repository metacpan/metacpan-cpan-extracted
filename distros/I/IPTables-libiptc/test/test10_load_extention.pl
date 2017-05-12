#!/usr/bin/perl -w

use lib qw(../blib/lib);
use lib qw(../blib/arch);

use lib qw(blib/lib);
use lib qw(blib/arch);

#use ExtUtils::testlib;

use diagnostics;

use Data::Dumper;

use IPTables::libiptc;


print "start\n";

$table_name = 'filter';
my $table = IPTables::libiptc::init("$table_name");

if (not defined $table) {
    print "\$table is undef\n -=-=- STRERR: $!\n";
    exit 1
}


my $success;

#my $chainname = "FORWARD";
my $chainname = "INPUT";
if( $success = $table->builtin("$chainname")) {
    print "Chain is buildin: $chainname\n";
} else {
    print "Chain is NOT buildin: $chainname\n";
}

sub call_do_command($) {
    $array_ref = shift;
    print "do_command:\"" . "@$array_ref" . "\"\n";
    if( $success = $table->iptables_do_command($array_ref)) {
	print " *do_command ok: $success\n *ERR:$!\n\n";
    } else {
	print " *do_command failed: $success\n *ERR:$!\n\n";
    }
}

#@arguments = ("-t", "filter", "-A", "INPUT");
#@arguments = ("-A", "$chainname", "-s", "1.2.3.4");
#@arguments = ("-N", "test");
#@arguments = ("badehat", "-N test");
#@arguments = ("badehat", "-N", "test");


#@arguments = ("-A test", "-p", "tcp");
#@arguments = ("-I", "test", "-s", "4.3.2.1");
#@arguments = ("-I", "test", "-s", "1.2.3.4", "-j", "ACCEPT");
#@arguments = ("-t", "filter", "-N test");
#@arguments = ("-h");
#@arguments = ("--help");
#@arguments = ["--help", "-m tcp"];

#@arguments = ("-A", "$chainname", "-s", "1.2.3.4", "-mtcp");
@arguments = ("-A", "$chainname", "-p", "tcp", "--dport", "123");
#@arguments = ("-A", "$chainname" );
#@arguments = ("-t", "filter", "-N test");

my $res = call_do_command(\@arguments);

print Dumper(\@arguments);

if( $table->commit()) {
    print "Commit OK\n";
} else {
    print "Commit FAILED\n";
}
