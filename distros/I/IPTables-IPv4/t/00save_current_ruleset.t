#!/usr/bin/perl

use IPTables::IPv4;
use FileHandle;
use Data::Dumper;

print "1..0\n";

$fh = new FileHandle(">/tmp/ruleset.txt");
print($fh "", Data::Dumper->Dump([\%IPTables::IPv4], ['rules']));
close($fh);

%IPTables::IPv4 = ();
# vim: ts=4
