#!/usr/bin/perl
use strict;
use warnings;
use GRID::Machine;
my $debug = @ARGV ? 1234 : 0;

my $m = GRID::Machine->new(
    host => "orion",
    prefix => '/tmp/perl5lib',                                                          
    startdir => '/tmp',                                                                               
    log => '/tmp/rperl$$.log',                                                                                           
    err => '/tmp/rperl$$.err',                                                                                
    debug => $debug,
    cleanup => 1,                                                                                 
    sendstdout => 1
    );

my $r = $m->system("anunknowncommand");
print "\nstdout: ", $r->stdout;
print "\nstderr: ", $r->stderr;
print "\nresult: ", $r->result;
print "\nerrcode: ", $r->errcode, "\n";

