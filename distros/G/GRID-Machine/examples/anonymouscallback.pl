#!/usr/bin/perl
use strict;
use GRID::Machine;
use Sys::Hostname;

my $host = shift || $ENV{GRID_REMOTE_MACHINE};

my $machine = GRID::Machine->new(host => $host, uses => [ 'Sys::Hostname' ]);

my $r = $machine->sub( remote => q{
    my $rsub = shift;

    gprint &hostname.": inside remote sub\n";
    my $retval = $rsub->(3);

    return  1+$retval;
} );

die $r->errmsg unless $r->ok;

my $a =  $machine->callback( 
           sub {
             print hostname().": inside anonymous inline callback. Args: (@_) \n";
             return shift() + 1;
           } 
         );

$r = $machine->remote( $a );

die $r->errmsg unless $r->noerr;

print "Result = ".$r->result."\n";
