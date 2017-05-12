#!/usr/bin/perl -w

use lib qw(../blib/lib);
use lib qw(../blib/arch);

use lib qw(blib/lib);
use lib qw(blib/arch);

#use ExtUtils::testlib;

use Data::Dumper;

use IPTables::libiptc;

$table_name = 'filter';
my $table = IPTables::libiptc::init("$table_name");

my $success;

my $chain = "badehat";
my @insert_rule     = ("-I", "FORWARD", "-s", "4.3.2.1", "-j", "$chain");
my @delete_rule     = ("-D", "FORWARD", "-s", "4.3.2.1", "-j", "$chain");
#my @delete_rule_num = ("-D", "FORWARD", "1");

$success = $table->create_chain($chain);

$success = $table->iptables_do_command(\@insert_rule);
my $refs = $table->get_references("$chain");
print "Chain: $chain has $refs references.\n";

$success = $table->iptables_do_command(\@delete_rule);
#$success = $table->iptables_do_command(\@delete_rule_num);
$refs = $table->get_references("$chain");
print "Chain: $chain has $refs references.\n";

if( !($table->delete_chain("$chain"))) {
    print "Error could not delete chain: $chain\n";
    print "Error string: $!\n";
}

if( $table->commit()) {
    print "Commit OK\n";
} else {
    print "Commit FAILED\n";
}
