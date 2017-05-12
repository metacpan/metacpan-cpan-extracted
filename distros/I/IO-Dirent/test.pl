#!/usr/local/bin/perl -w
use strict;
use Test;

BEGIN { plan tests => 5}
use blib;
use IO::Dirent qw(:ALL);
ok(1);

#open(FOO, ".");
#use Devel::Peek;
#Dump(*FOO);
#close FOO;
#print "=====================\n";

opendir DIR, ".";
#Dump(*DIR);
#print "=====================\n";

my @entries = readdirent(DIR);
closedir DIR;

for my $entry ( @entries ) {
    if( $entry->{'name'} eq 'blib' ) {
	skip( ! exists $entry->{'type'}, $entry->{'type'} == DT_DIR );
    }

    if( $entry->{'name'} eq 'Dirent.pm' ) {
	skip( ! exists $entry->{'type'}, $entry->{'type'} == DT_REG );
    }
}

opendir DIR, '.';
while( my $entry = nextdirent(DIR) ) {
    if( $entry->{'name'} eq 'blib' ) {
        skip( ! exists $entry->{'type'}, $entry->{'type'} == DT_DIR );
    }

    if( $entry->{'name'} eq 'Dirent.pm' ) {
	skip( ! exists $entry->{'type'}, $entry->{'type'} == DT_REG );
    }
}
closedir DIR;
