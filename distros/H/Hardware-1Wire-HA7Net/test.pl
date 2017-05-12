#!/usr/bin/perl -w

use lib::Hardware::1Wire::HA7Net;

print "What is the IP address or name of your HA7Net? ";
chomp($where = <STDIN>);
$where =~ s#^http://##;
print "If you know the 16-digit hex address of a 1-Wire device connected to\n";
print "your HA7Net, type it here.  Otherwise just hit return: ";
chomp($device = <STDIN>);
if ($device) {
    print "Creating unscanned HA7Net\n";
    $x = new Hardware::1Wire::HA7Net ("http://$where", 0);
    print "Reading $device (should exist)\n";
    @results = $x->read($device);
    print "Reading 0300000021664710 (doesn't exist)\n";
    @results = $x->read("0300000021664710");
    while (($k, $v) = splice @results, 0, 2) {
	print "$k $v\n";
	}
    print "Known sensors: ",
	join(", ", map { $_->address } $x->sensors), "\n\n";
    print "Rescanning for more sensors...\n";

    if ($x->scan (\@new, \@gone)) {
	print "New:\n";
	for $s (@new) {
	    print "\t", scalar $s->type, " ", $s->address, "\n";
	    }
	print "\tNone\n"	unless @new;
	print "Missing:\n";
	for $s (@gone) {
	    print "\t", scalar $s->type, " ", $s->address, "\n";
	    }
	print "\tNone\n"	unless @gone;
	}
    else {
	print "No changes\n";
	}
    }

print "\nCreating scanned HA7Net\n";
$x = new Hardware::1Wire::HA7Net ("http://$where");

print "Initialized HA7Net - firmware version ", $x->version, "\n";

print "Individual sensor read:\n";
for $s ($x->sensors) {
    if ($s->isa("ds1820")) {
	print join " ", "DS1820", $s->temperature, "\n";
	}
    elsif ($s->isa("ds18b20")) {
	print join " ", "DS18B20", $s->temperature, "\n";
	}
    elsif ($s->isa("hmp2001s")) {
	print join " ", "HMP2001S", $s->value, "\n";
	}
    else {
	print "Unrecognized sensor type: ", $s->type, "\n";
	}
    push @addrs, $s->address;
    }

print "Group read 1:\n";
@results = $x->read(@addrs);
while (($k, $v) = splice @results, 0, 2) {
    print "$k $v\n";
    }

print "Group read 2:\n";
@results = $x->read($x->sensors);
while (($k, $v) = splice @results, 0, 2) {
    print "$k $v\n";
    }

print "Group read 3:\n";
@results = $x->read();
while (($k, $v) = splice @results, 0, 2) {
    print "$k $v\n";
    }

print "Change the sensors on the HA7Net (or not) and hit return: ";
<STDIN>;
print "\nRescanning...\n";

if ($x->scan (\@new, \@gone)) {
    print "New:\n";
    for $s (@new) {
	print "\t", scalar $s->type, " ", $s->address, "\n";
	}
    print "\tNone\n"	unless @new;
    print "Missing:\n";
    for $s (@gone) {
	print "\t", scalar $s->type, " ", $s->address, "\n";
	}
    print "\tNone\n"	unless @gone;
    }
else {
    print "No changes\n";
    }
