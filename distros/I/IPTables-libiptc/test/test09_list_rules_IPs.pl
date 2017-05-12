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

my $chain = 'FORWARD';

my $a = $table->list_rules_IPs('src', $chain );
print Dumper($a);

if (!defined($a)) {
    print "Err not defined\n";
}

foreach my $rule ($table->list_rules_IPs('src', $chain)) {
    print "Src => $rule\n";
}
