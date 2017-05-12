#!/usr/bin/perl

use lib 'lib';
use strict;
use Filesys::ZFS;

my $ZFS = Filesys::ZFS->new;

$ZFS->init || die $ZFS->errstr;

print "File system is: " . ($ZFS->is_healthy ? 'healthy' : 'not healthy') . "\n";

for my $type (qw(pools snapshots volumes bookmarks)){
	print "Active $type:\n";
	my @data = $ZFS->list($type);

	if(@data){
		for my $obj (@data){
			print "         Name: " . $obj->name . "\n";
			print "        State: " . $obj->state . "\n";
			print "       Errors: " . $obj->errors . "\n";
			print "  Read Errors: " . $obj->read . "\n";
			print " Write Errors: " . $obj->write . "\n";
			print "   CRC Errors: " . $obj->cksum . "\n";
			print "        Mount: " . $obj->mount . "\n";
			print "         Scan: " . $obj->scan . "\n";
			print "         Free: " . $obj->free . "\n";
			print "         Used: " . $obj->used . "\n";
			print "   Referenced: " . $obj->referenced . "\n";
			print "       Status: " . $obj->status . "\n";
			print "       Action: " . $obj->action . "\n\n";
			print "Configuraiton: " . $obj->config . "\n\n";
			print "    Providers:\n";


			providers($obj);

			print "\n\n\n";
		}
	} else {
		print "\tNone\n";
	}

	print "\n";
}


sub providers {
	my ($p, $tab) = @_;
	for my $prov ($p->providers){
		if($prov->is_vdev){
			print (("\t" x $tab) . "\tVirtual Device: " . $prov->name . "\n");
			print (("\t" x $tab) . "\t   Read Errors: " . $prov->read . "\n");
			print (("\t" x $tab) . "\t  Write Errors: " . $prov->write . "\n");
			print (("\t" x $tab) . "\t    CRC Errors: " . $prov->cksum . "\n");
			print (("\t" x $tab) . "\t         State: " . $prov->state . "\n\n");

			providers($prov, $tab+1);
		} else {
			print (("\t" x $tab) . "\tBlock Device: " . $prov->name . "\n");	
			print (("\t" x $tab) . "\t Read Errors: " . $prov->read . "\n");
			print (("\t" x $tab) . "\tWrite Errors: " . $prov->write . "\n");
			print (("\t" x $tab) . "\t  CRC Errors: " . $prov->cksum . "\n");
			print (("\t" x $tab) . "\t       State: " . $prov->state . "\n\n");
		}
	}
}

